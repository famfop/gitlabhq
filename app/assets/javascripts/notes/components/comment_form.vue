<script>
import { GlAlert, GlButton, GlIcon, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import $ from 'jquery';
import { mapActions, mapGetters, mapState } from 'vuex';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import { createAlert } from '~/alert';
import { badgeState } from '~/issuable/components/status_box.vue';
import { STATUS_CLOSED, STATUS_MERGED, STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { containsSensitiveToken, confirmSensitiveAction } from '~/lib/utils/secret_detection';
import {
  capitalizeFirstCharacter,
  convertToCamelCase,
  slugifyWithUnderscore,
} from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';

import * as constants from '../constants';
import eventHub from '../event_hub';
import { COMMENT_FORM } from '../i18n';
import { createNoteErrorMessages } from '../utils';

import issuableStateMixin from '../mixins/issuable_state';
import CommentFieldLayout from './comment_field_layout.vue';
import CommentTypeDropdown from './comment_type_dropdown.vue';
import DiscussionLockedWidget from './discussion_locked_widget.vue';
import NoteSignedOutWidget from './note_signed_out_widget.vue';

const ATTACHMENT_REGEXP = /!?\[.*?\]\(\/uploads\/[0-9a-f]{32}\/.*?\)/;
export default {
  name: 'CommentForm',
  i18n: COMMENT_FORM,
  components: {
    NoteSignedOutWidget,
    DiscussionLockedWidget,
    MarkdownEditor,
    GlAlert,
    GlButton,
    TimelineEntryItem,
    GlIcon,
    CommentFieldLayout,
    CommentTypeDropdown,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), issuableStateMixin],
  props: {
    noteableType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      note: '',
      noteType: constants.COMMENT,
      errors: [],
      noteIsInternal: false,
      isSubmitting: false,
      formFieldProps: {
        'aria-label': this.$options.i18n.comment,
        placeholder: this.$options.i18n.bodyPlaceholder,
        id: 'note-body',
        name: 'note[note]',
        class: 'js-note-text note-textarea js-gfm-input markdown-area',
        'data-qa-selector': 'comment_field',
      },
    };
  },
  computed: {
    ...mapGetters([
      'getCurrentUserLastNote',
      'getUserData',
      'getNoteableData',
      'getNoteableDataByProp',
      'getNotesData',
      'openState',
      'hasDrafts',
    ]),
    ...mapState(['isToggleStateButtonLoading']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    noteableDisplayName() {
      const displayNameMap = {
        [constants.ISSUE_NOTEABLE_TYPE]: this.$options.i18n.issue,
        [constants.EPIC_NOTEABLE_TYPE]: this.$options.i18n.epic,
        [constants.MERGE_REQUEST_NOTEABLE_TYPE]: this.$options.i18n.mergeRequest,
      };

      const noteableTypeKey =
        constants.NOTEABLE_TYPE_MAPPING[this.noteableType] || constants.ISSUE_NOTEABLE_TYPE;
      return displayNameMap[noteableTypeKey];
    },
    isLoggedIn() {
      return this.getUserData.id;
    },
    commentButtonTitle() {
      const { comment, internalComment, startThread, startInternalThread } = this.$options.i18n;
      if (this.noteIsInternal) {
        return this.noteType === constants.COMMENT ? internalComment : startInternalThread;
      }
      return this.noteType === constants.COMMENT ? comment : startThread;
    },
    discussionsRequireResolution() {
      return this.getNoteableData.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE;
    },
    isOpen() {
      return this.openState === STATUS_OPEN || this.openState === STATUS_REOPENED;
    },
    canCreateNote() {
      return this.getNoteableData.current_user.can_create_note;
    },
    canSetInternalNote() {
      return (
        this.getNoteableData.current_user.can_create_confidential_note &&
        (this.isIssue || this.isEpic)
      );
    },
    issueActionButtonTitle() {
      const openOrClose = this.isOpen ? 'close' : 'reopen';

      if (this.note.length) {
        return sprintf(this.$options.i18n.actionButton.withNote[openOrClose], {
          actionText: this.commentButtonTitle,
          noteable: this.noteableDisplayName,
        });
      }

      return sprintf(this.$options.i18n.actionButton.withoutNote[openOrClose], {
        noteable: this.noteableDisplayName,
      });
    },
    actionButtonClassNames() {
      return {
        'btn-reopen': !this.isOpen,
        'btn-close': this.isOpen,
        'js-note-target-close': this.isOpen,
        'js-note-target-reopen': !this.isOpen,
      };
    },
    markdownDocsPath() {
      return this.getNotesData.markdownDocsPath;
    },
    markdownPreviewPath() {
      return this.getNoteableData.preview_note_path;
    },
    author() {
      return this.getUserData;
    },
    canToggleIssueState() {
      return (
        this.getNoteableData.current_user.can_update &&
        this.openState !== STATUS_MERGED &&
        !this.closedAndLocked
      );
    },
    closedAndLocked() {
      return !this.isOpen && this.isLocked(this.getNoteableData);
    },
    endpoint() {
      return this.getNoteableData.create_note_path;
    },
    draftEndpoint() {
      return this.getNotesData.draftsPath;
    },
    isIssue() {
      return constants.NOTEABLE_TYPE_MAPPING[this.noteableType] === constants.ISSUE_NOTEABLE_TYPE;
    },
    isEpic() {
      return constants.NOTEABLE_TYPE_MAPPING[this.noteableType] === constants.EPIC_NOTEABLE_TYPE;
    },
    trackingLabel() {
      return slugifyWithUnderscore(`${this.commentButtonTitle} button`);
    },
    disableSubmitButton() {
      return this.note.length === 0 || this.isSubmitting;
    },
    containsLink() {
      return ATTACHMENT_REGEXP.test(this.note);
    },
    autosaveKey() {
      if (this.isLoggedIn) {
        const noteableType = capitalizeFirstCharacter(convertToCamelCase(this.noteableType));
        return `${this.$options.i18n.note}/${noteableType}/${this.getNoteableData.id}`;
      }

      return null;
    },
  },
  watch: {
    noteIsInternal(val) {
      this.formFieldProps.placeholder = val
        ? this.$options.i18n.bodyPlaceholderInternal
        : this.$options.i18n.bodyPlaceholder;
    },
  },
  mounted() {
    // jQuery is needed here because it is a custom event being dispatched with jQuery.
    $(document).on('issuable:change', (e, isClosed) => {
      this.toggleIssueLocalState(isClosed ? STATUS_CLOSED : STATUS_REOPENED);
    });
  },
  methods: {
    ...mapActions([
      'saveNote',
      'stopPolling',
      'restartPolling',
      'removePlaceholderNotes',
      'closeIssuable',
      'reopenIssuable',
      'toggleIssueLocalState',
    ]),
    handleSaveError({ data, status }) {
      this.errors = createNoteErrorMessages(data, status);
    },
    handleSaveDraft() {
      this.handleSave({ isDraft: true });
    },
    async handleSave({ withIssueAction = false, isDraft = false } = {}) {
      this.errors = [];

      if (this.note.length) {
        const noteData = {
          endpoint: isDraft ? this.draftEndpoint : this.endpoint,
          data: {
            note: {
              noteable_type: this.noteableType,
              noteable_id: this.getNoteableData.id,
              internal: this.noteIsInternal,
              note: this.note,
            },
            merge_request_diff_head_sha: this.getNoteableData.diff_head_sha,
          },
          isDraft,
        };

        if (this.noteType === constants.DISCUSSION) {
          noteData.data.note.type = constants.DISCUSSION_NOTE;
        }

        if (containsSensitiveToken(this.note)) {
          const confirmed = await confirmSensitiveAction();
          if (!confirmed) {
            return;
          }
        }

        this.note = ''; // Empty textarea while being requested. Repopulate in catch
        this.stopPolling();

        this.isSubmitting = true;

        trackSavedUsingEditor(
          this.$refs.markdownEditor.isContentEditorActive,
          `${this.noteableType}_${this.noteType}`,
        );

        this.saveNote(noteData)
          .then(() => {
            this.restartPolling();
            this.discard();

            if (withIssueAction) {
              this.toggleIssueState();
            }
          })
          .catch(({ response }) => {
            this.handleSaveError(response);

            this.note = noteData.data.note.note; // Restore textarea content.
            this.removePlaceholderNotes();
          })
          .finally(() => {
            this.isSubmitting = false;
          });
      } else {
        this.toggleIssueState();
      }
    },
    handleEnter() {
      if (this.hasDrafts) {
        this.handleSaveDraft();
      } else {
        this.handleSave();
      }
    },
    toggleIssueState() {
      if (this.isIssue) {
        // We want to invoke the close/reopen logic in the issue header
        // since that is where the blocked-by issues modal logic is also defined
        eventHub.$emit('toggle.issuable.state');
        return;
      }

      const toggleState = this.isOpen ? this.closeIssuable : this.reopenIssuable;

      toggleState()
        .then(() => badgeState.updateStatus && badgeState.updateStatus())
        .then(refreshUserMergeRequestCounts)
        .catch(() =>
          createAlert({
            message: constants.toggleStateErrorMessage[this.noteableType][this.openState],
          }),
        );
    },
    discard() {
      this.note = '';
      this.noteIsInternal = false;
      this.$refs.markdownEditor.togglePreview(false);
    },
    editCurrentUserLastNote() {
      if (this.note === '') {
        const lastNote = this.getCurrentUserLastNote;

        if (lastNote) {
          eventHub.$emit('enterEditMode', {
            noteId: lastNote.id,
          });
        }
      }
    },
    hasEmailParticipants() {
      return this.getNoteableData.issue_email_participants?.length;
    },
    dismissError(index) {
      this.errors.splice(index, 1);
    },
    onInput(value) {
      this.note = value;
    },
  },
};
</script>

<template>
  <div>
    <note-signed-out-widget v-if="!isLoggedIn" />
    <discussion-locked-widget v-else-if="!canCreateNote" :issuable-type="noteableDisplayName" />
    <ul v-else-if="canCreateNote" class="notes notes-form timeline">
      <timeline-entry-item class="note-form">
        <gl-alert
          v-for="(error, index) in errors"
          :key="index"
          variant="danger"
          class="gl-mb-2"
          @dismiss="() => dismissError(index)"
        >
          {{ error }}
        </gl-alert>
        <div class="timeline-content timeline-content-form">
          <form ref="commentForm" class="new-note common-note-form gfm-form js-main-target-form">
            <comment-field-layout
              :with-alert-container="true"
              :noteable-data="getNoteableData"
              :is-internal-note="noteIsInternal"
              :noteable-type="noteableType"
              :contains-link="containsLink"
            >
              <markdown-editor
                ref="markdownEditor"
                :enable-content-editor="Boolean(glFeatures.contentEditorOnIssues)"
                :value="note"
                :render-markdown-path="markdownPreviewPath"
                :markdown-docs-path="markdownDocsPath"
                :add-spacing-classes="false"
                :form-field-props="formFieldProps"
                :autosave-key="autosaveKey"
                :disabled="isSubmitting"
                :autocomplete-data-sources="autocompleteDataSources"
                supports-quick-actions
                @keydown.up="editCurrentUserLastNote()"
                @keydown.meta.enter="handleEnter()"
                @keydown.ctrl.enter="handleEnter()"
                @input="onInput"
              />
            </comment-field-layout>
            <div class="note-form-actions">
              <template v-if="hasDrafts">
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-to-review-button"
                  type="submit"
                  category="primary"
                  variant="confirm"
                  @click.prevent="handleSaveDraft()"
                  >{{ __('Add to review') }}</gl-button
                >
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-comment-now-button"
                  category="secondary"
                  @click.prevent="handleSave()"
                  >{{ __('Add comment now') }}</gl-button
                >
              </template>
              <template v-else>
                <gl-form-checkbox
                  v-if="canSetInternalNote"
                  v-model="noteIsInternal"
                  class="gl-mb-2"
                  data-testid="internal-note-checkbox"
                >
                  {{ $options.i18n.internal }}
                  <gl-icon
                    v-gl-tooltip:tooltipcontainer.bottom
                    name="question-o"
                    :size="16"
                    :title="$options.i18n.internalVisibility"
                    class="gl-text-blue-500"
                  />
                </gl-form-checkbox>
                <comment-type-dropdown
                  v-model="noteType"
                  class="gl-mr-3"
                  :disabled="disableSubmitButton"
                  :tracking-label="trackingLabel"
                  :is-internal-note="noteIsInternal"
                  :noteable-display-name="noteableDisplayName"
                  :discussions-require-resolution="discussionsRequireResolution"
                  @click="handleSave"
                />
              </template>
              <gl-button
                v-if="canToggleIssueState"
                :loading="isToggleStateButtonLoading"
                :class="[actionButtonClassNames, 'btn-comment btn-comment-and-close']"
                :disabled="isSubmitting"
                data-testid="close-reopen-button"
                @click="handleSave({ withIssueAction: true })"
                >{{ issueActionButtonTitle }}</gl-button
              >
            </div>
          </form>
        </div>
      </timeline-entry-item>
    </ul>
  </div>
</template>
