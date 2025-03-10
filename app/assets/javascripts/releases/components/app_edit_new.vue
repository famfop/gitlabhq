<script>
import {
  GlButton,
  GlDatepicker,
  GlFormCheckbox,
  GlFormInput,
  GlFormGroup,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { isSameOriginUrl, getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MilestoneCombobox from '~/milestones/components/milestone_combobox.vue';
import { BACK_URL_PARAM } from '~/releases/constants';
import { putCreateReleaseNotification } from '~/releases/release_notification_service';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import AssetLinksForm from './asset_links_form.vue';
import ConfirmDeleteModal from './confirm_delete_modal.vue';
import TagField from './tag_field.vue';

export default {
  name: 'ReleaseEditNewApp',
  components: {
    GlFormCheckbox,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlDatepicker,
    GlLink,
    GlSprintf,
    ConfirmDeleteModal,
    MarkdownField,
    AssetLinksForm,
    MilestoneCombobox,
    TagField,
  },
  computed: {
    ...mapState('editNew', [
      'isExistingRelease',
      'isFetchingRelease',
      'isUpdatingRelease',
      'fetchError',
      'markdownDocsPath',
      'markdownPreviewPath',
      'editReleaseDocsPath',
      'upcomingReleaseDocsPath',
      'releasesPagePath',
      'release',
      'newMilestonePath',
      'manageMilestonesPath',
      'projectId',
      'projectPath',
      'groupId',
      'groupMilestonesAvailable',
      'tagNotes',
    ]),
    ...mapGetters('editNew', ['isValid', 'formattedReleaseNotes']),
    showForm() {
      return Boolean(!this.isFetchingRelease && !this.fetchError && this.release);
    },
    releaseTitle: {
      get() {
        return this.$store.state.editNew.release.name;
      },
      set(title) {
        this.updateReleaseTitle(title);
      },
    },
    releaseNotes: {
      get() {
        return this.$store.state.editNew.release.description;
      },
      set(notes) {
        this.updateReleaseNotes(notes);
      },
    },
    releaseMilestones: {
      get() {
        return this.$store.state.editNew.release.milestones;
      },
      set(milestones) {
        this.updateReleaseMilestones(milestones);
      },
    },
    includeTagNotes: {
      get() {
        return this.$store.state.editNew.includeTagNotes;
      },
      set(includeTagNotes) {
        this.updateIncludeTagNotes(includeTagNotes);
      },
    },
    releasedAt: {
      get() {
        return this.release.releasedAt;
      },
      set(date) {
        this.updateReleasedAt(date);
      },
    },
    cancelPath() {
      const backUrl = getParameterByName(BACK_URL_PARAM);

      if (isSameOriginUrl(backUrl)) {
        return backUrl;
      }

      return this.releasesPagePath;
    },
    saveButtonLabel() {
      return this.isExistingRelease ? __('Save changes') : __('Create release');
    },
    isFormSubmissionDisabled() {
      return this.isUpdatingRelease || !this.isValid;
    },
    milestoneComboboxExtraLinks() {
      return [
        {
          text: __('Create new'),
          url: this.newMilestonePath,
        },
        {
          text: __('Manage milestones'),
          url: this.manageMilestonesPath,
        },
      ];
    },
  },
  async mounted() {
    await this.initializeRelease();

    if (this.release?.tagName) {
      // Focus the release title input if a tag was preselected
      this.$refs.releaseTitleInput.$el.focus();
    } else {
      // Focus the first non-disabled input or button element otherwise
      this.$el.querySelector('input:enabled, button:enabled').focus();
    }
  },
  methods: {
    ...mapActions('editNew', [
      'initializeRelease',
      'saveRelease',
      'deleteRelease',
      'updateReleaseTitle',
      'updateReleaseNotes',
      'updateReleaseMilestones',
      'updateIncludeTagNotes',
      'updateReleasedAt',
    ]),
    submitForm() {
      if (!this.isFormSubmissionDisabled) {
        this.saveRelease();
        putCreateReleaseNotification(this.projectPath, this.release.name);
      }
    },
  },
};
</script>
<template>
  <div class="d-flex flex-column">
    <p class="pt-3 js-subtitle-text">
      <gl-sprintf
        :message="
          __(
            'Releases are based on Git tags. We recommend tags that use semantic versioning, for example %{codeStart}1.0.0%{codeEnd}, %{codeStart}2.1.0-pre%{codeEnd}.',
          )
        "
      >
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <form v-if="showForm" class="js-quick-submit" @submit.prevent="submitForm">
      <tag-field />
      <gl-form-group>
        <label for="release-title">{{ __('Release title') }}</label>
        <gl-form-input
          id="release-title"
          ref="releaseTitleInput"
          v-model="releaseTitle"
          type="text"
          class="form-control"
        />
      </gl-form-group>
      <gl-form-group class="w-50" data-testid="milestones-field">
        <label>{{ __('Milestones') }}</label>
        <div class="d-flex flex-column col-md-6 col-sm-10 pl-0">
          <milestone-combobox
            v-model="releaseMilestones"
            :project-id="projectId"
            :group-id="groupId"
            :group-milestones-available="groupMilestonesAvailable"
            :extra-links="milestoneComboboxExtraLinks"
          />
        </div>
      </gl-form-group>
      <gl-form-group :label="__('Release date')" label-for="release-released-at">
        <template #label-description>
          <gl-sprintf
            :message="
              __(
                'The date when the release is ready. A release with a date in the future is labeled as an %{linkStart}Upcoming Release%{linkEnd}.',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="upcomingReleaseDocsPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
        <gl-datepicker id="release-released-at" v-model="releasedAt" :default-date="releasedAt" />
      </gl-form-group>
      <gl-form-group data-testid="release-notes">
        <label for="release-notes">{{ __('Release notes') }}</label>
        <div class="common-note-form">
          <markdown-field
            :can-attach-file="true"
            :markdown-preview-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocsPath"
            :add-spacing-classes="false"
            :textarea-value="formattedReleaseNotes"
          >
            <template #textarea>
              <textarea
                id="release-notes"
                v-model="releaseNotes"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="__('Release notes')"
                :placeholder="__('Write your release notes or drag your files here…')"
              ></textarea>
            </template>
          </markdown-field>
        </div>
      </gl-form-group>
      <gl-form-group v-if="!isExistingRelease">
        <gl-form-checkbox v-model="includeTagNotes">
          {{ s__('Release|Include message from the annotated tag.') }}

          <template #help>
            <gl-sprintf
              :message="
                s__(
                  'Release|You can edit the content later by editing the release. %{linkStart}How do I edit a release?%{linkEnd}',
                )
              "
            >
              <template #link="{ content }">
                <gl-link :href="editReleaseDocsPath">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
        </gl-form-checkbox>
      </gl-form-group>

      <asset-links-form />

      <div class="d-flex gl-gap-x-3 pt-3">
        <gl-button
          class="js-no-auto-disable"
          category="primary"
          variant="confirm"
          type="submit"
          :disabled="isFormSubmissionDisabled"
          data-testid="submit-button"
        >
          {{ saveButtonLabel }}
        </gl-button>
        <confirm-delete-modal v-if="isExistingRelease" @delete="deleteRelease" />
        <gl-button :href="cancelPath" class="js-cancel-button">{{ __('Cancel') }}</gl-button>
      </div>
    </form>
  </div>
</template>
