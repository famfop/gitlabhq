<script>
import {
  GlTooltipDirective,
  GlIcon,
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlFormCheckbox,
  GlLoadingIcon,
} from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { IdState } from 'vendor/vue-virtual-scroller';
import { scrollToElement } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, s__, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { DIFF_FILE_AUTOMATIC_COLLAPSE } from '../constants';
import { DIFF_FILE_HEADER } from '../i18n';
import { collapsedType, isCollapsed } from '../utils/diff_file';
import { reviewable } from '../utils/file_reviews';

import DiffStats from './diff_stats.vue';

export default {
  components: {
    ClipboardButton,
    GlIcon,
    DiffStats,
    GlBadge,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlFormCheckbox,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [IdState({ idProp: (vm) => vm.diffFile.file_hash }), glFeatureFlagsMixin()],
  i18n: {
    ...DIFF_FILE_HEADER,
    compareButtonLabel: __('Compare submodule commit revisions'),
    fileModeTooltip: __('File permissions'),
  },
  inject: {
    showGenerateTestFileButton: {
      default: false,
    },
  },
  props: {
    discussionPath: {
      type: String,
      required: false,
      default: '',
    },
    diffFile: {
      type: Object,
      required: true,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
    addMergeRequestButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    viewDiffsFileByFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    showLocalFileReviews: {
      type: Boolean,
      required: false,
      default: false,
    },
    reviewed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  idState() {
    return {
      moreActionsShown: false,
    };
  },
  computed: {
    ...mapState('diffs', ['latestDiff']),
    ...mapGetters('diffs', ['diffHasExpandedDiscussions', 'diffHasDiscussions']),
    ...mapGetters(['getNoteableData']),
    diffContentIDSelector() {
      return `#diff-content-${this.diffFile.file_hash}`;
    },

    titleLink() {
      if (this.diffFile.submodule) {
        return this.diffFile.submodule_tree_url || this.diffFile.submodule_link;
      }

      if (!this.discussionPath) {
        return this.diffContentIDSelector;
      }

      return this.discussionPath;
    },
    submoduleDiffCompareLinkText() {
      if (this.diffFile.submodule_compare) {
        const truncatedOldSha = escape(truncateSha(this.diffFile.submodule_compare.old_sha));
        const truncatedNewSha = escape(truncateSha(this.diffFile.submodule_compare.new_sha));
        return sprintf(
          __('Compare %{oldCommitId}...%{newCommitId}'),
          {
            oldCommitId: `<span class="commit-sha">${truncatedOldSha}</span>`,
            newCommitId: `<span class="commit-sha">${truncatedNewSha}</span>`,
          },
          false,
        );
      }
      return null;
    },
    filePath() {
      if (this.diffFile.submodule) {
        return `${this.diffFile.file_path} @ ${truncateSha(this.diffFile.blob.id)}`;
      }

      if (this.diffFile.deleted_file) {
        return sprintf(__('%{filePath} deleted'), { filePath: this.diffFile.file_path }, false);
      }

      return this.diffFile.file_path;
    },
    isUsingLfs() {
      return this.diffFile.stored_externally && this.diffFile.external_storage === 'lfs';
    },
    isCollapsed() {
      return isCollapsed(this.diffFile, { fileByFile: this.viewDiffsFileByFile });
    },
    collapseIcon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
    },
    viewFileButtonText() {
      const truncatedContentSha = escape(truncateSha(this.diffFile.content_sha));
      return sprintf(
        s__('MergeRequests|View file @ %{commitId}'),
        { commitId: truncatedContentSha },
        false,
      );
    },
    viewReplacedFileButtonText() {
      const truncatedBaseSha = escape(truncateSha(this.diffFile.diff_refs.base_sha));
      return sprintf(s__('MergeRequests|View replaced file @ %{commitId}'), {
        commitId: truncatedBaseSha,
      });
    },
    gfmCopyText() {
      return `\`${this.diffFile.file_path}\``;
    },
    isFileRenamed() {
      return this.diffFile.renamed_file;
    },
    isModeChanged() {
      return this.diffFile.mode_changed;
    },
    expandDiffToFullFileTitle() {
      if (this.diffFile.isShowingFullFile) {
        return s__('MRDiff|Show changes only');
      }
      return s__('MRDiff|Show full file');
    },
    showEditButton() {
      return (
        this.diffFile.blob?.readable_text &&
        !this.diffFile.deleted_file &&
        (this.diffFile.edit_path || this.diffFile.ide_edit_path)
      );
    },
    isReviewable() {
      return reviewable(this.diffFile);
    },
    externalUrlLabel() {
      return sprintf(__('View on %{url}'), { url: this.diffFile.formatted_external_url });
    },
    labelToggleFile() {
      return this.expanded ? __('Hide file contents') : __('Show file contents');
    },
    showCommentButton() {
      return this.getNoteableData.current_user.can_create_note;
    },
  },
  watch: {
    'idState.moreActionsShown': {
      handler(val) {
        const el = this.$el.closest('.vue-recycle-scroller__item-view');

        if (el) {
          // We can't add a style with Vue because of the way the virtual
          // scroller library renders the diff files
          el.style.zIndex = val ? '1' : null;
        }
      },
    },
  },
  methods: {
    ...mapActions('diffs', [
      'toggleFileDiscussions',
      'toggleFileDiscussionWrappers',
      'toggleFullDiff',
      'setCurrentFileHash',
      'reviewFile',
      'setFileCollapsedByUser',
      'setGenerateTestFilePath',
      'toggleFileCommentForm',
    ]),
    handleToggleFile() {
      this.$emit('toggleFile');
    },
    showForkMessage(e) {
      if (this.canCurrentUserFork && !this.diffFile.can_modify_blob) {
        e.preventDefault();
        this.$emit('showForkMessage');
      }
    },
    handleFileNameClick(e) {
      const isLinkToOtherPage =
        this.diffFile.submodule_tree_url || this.diffFile.submodule_link || this.discussionPath;

      if (!isLinkToOtherPage) {
        e.preventDefault();
        const selector = this.diffContentIDSelector;
        scrollToElement(document.querySelector(selector));
        window.location.hash = selector;
        if (!this.viewDiffsFileByFile) {
          this.setCurrentFileHash(this.diffFile.file_hash);
        }
      }
    },
    setMoreActionsShown(val) {
      this.idState.moreActionsShown = val;
    },
    toggleReview(newReviewedStatus) {
      const autoCollapsed =
        this.isCollapsed && collapsedType(this.diffFile) === DIFF_FILE_AUTOMATIC_COLLAPSE;
      const open = this.expanded;
      const closed = !open;
      const reviewed = newReviewedStatus;

      this.reviewFile({ file: this.diffFile, reviewed });

      if (reviewed && autoCollapsed) {
        this.setFileCollapsedByUser({
          filePath: this.diffFile.file_path,
          collapsed: true,
        });
      }

      if ((open && reviewed) || (closed && !reviewed)) {
        this.$emit('toggleFile');
      }
    },
  },
};
</script>

<template>
  <div
    ref="header"
    :class="{
      'gl-z-dropdown-menu!': idState.moreActionsShown,
      'is-sidebar-moved': glFeatures.movedMrSidebar,
    }"
    class="js-file-title file-title file-title-flex-parent gl-border"
    data-qa-selector="file_title_container"
    :data-qa-file-name="filePath"
    @click.self="handleToggleFile"
  >
    <div class="file-header-content">
      <gl-button
        v-if="collapsible"
        ref="collapseButton"
        class="gl-mr-2"
        category="tertiary"
        size="small"
        :icon="collapseIcon"
        :aria-label="labelToggleFile"
        @click.stop="handleToggleFile"
      />
      <a
        ref="titleWrapper"
        :v-once="!viewDiffsFileByFile"
        class="gl-mr-2 gl-text-decoration-none! gl-word-break-all"
        :href="titleLink"
        @click="handleFileNameClick"
      >
        <span v-if="isFileRenamed">
          <strong
            v-gl-tooltip
            v-safe-html="diffFile.old_path_html"
            :title="diffFile.old_path"
            class="file-title-name"
          ></strong>
          →
          <strong
            v-gl-tooltip
            v-safe-html="diffFile.new_path_html"
            :title="diffFile.new_path"
            class="file-title-name"
          ></strong>
        </span>

        <strong
          v-else
          v-gl-tooltip
          :title="filePath"
          class="file-title-name"
          data-container="body"
          data-qa-selector="file_name_content"
        >
          {{ filePath }}
        </strong>
      </a>

      <clipboard-button
        :title="__('Copy file path')"
        :text="diffFile.file_path"
        :gfm="gfmCopyText"
        size="small"
        data-testid="diff-file-copy-clipboard"
        category="tertiary"
        data-track-action="click_copy_file_button"
        data-track-label="diff_copy_file_path_button"
        data-track-property="diff_copy_file"
      />

      <small
        v-if="isModeChanged"
        ref="fileMode"
        v-gl-tooltip.hover
        class="mr-1"
        :title="$options.i18n.fileModeTooltip"
      >
        {{ diffFile.a_mode }} → {{ diffFile.b_mode }}
      </small>

      <gl-badge v-if="isUsingLfs" variant="neutral" class="gl-mr-2" data-testid="label-lfs">{{
        __('LFS')
      }}</gl-badge>
    </div>

    <div
      v-if="!diffFile.submodule && addMergeRequestButtons"
      class="file-actions d-flex align-items-center gl-ml-auto gl-align-self-start"
    >
      <diff-stats
        :diff-file="diffFile"
        :added-lines="diffFile.added_lines"
        :removed-lines="diffFile.removed_lines"
      />
      <gl-form-checkbox
        v-if="isReviewable && showLocalFileReviews"
        v-gl-tooltip.hover
        data-testid="fileReviewCheckbox"
        class="gl-mr-5 gl-mb-n3 gl-display-flex gl-align-items-center"
        :title="$options.i18n.fileReviewTooltip"
        :checked="reviewed"
        @change="toggleReview"
      >
        {{ $options.i18n.fileReviewLabel }}
      </gl-form-checkbox>
      <gl-button
        v-if="showCommentButton"
        v-gl-tooltip.hover
        :title="__('Comment on this file')"
        :aria-label="__('Comment on this file')"
        icon="comment"
        category="tertiary"
        size="small"
        class="gl-mr-3 btn-icon"
        data-testid="comment-files-button"
        @click="toggleFileCommentForm(diffFile.file_path)"
      />
      <gl-button-group class="gl-pt-0!">
        <gl-button
          v-if="diffFile.external_url"
          ref="externalLink"
          v-gl-tooltip.hover
          :href="diffFile.external_url"
          :title="externalUrlLabel"
          :aria-label="externalUrlLabel"
          target="_blank"
          data-track-action="click_toggle_external_button"
          data-track-label="diff_toggle_external_button"
          data-track-property="diff_toggle_external"
          icon="external-link"
        />
        <gl-dropdown
          v-gl-tooltip.hover.focus="$options.i18n.optionsDropdownTitle"
          size="small"
          category="tertiary"
          right
          toggle-class="btn-icon js-diff-more-actions"
          class="gl-pt-0!"
          data-qa-selector="dropdown_button"
          lazy
          @show="setMoreActionsShown(true)"
          @hidden="setMoreActionsShown(false)"
        >
          <template #button-content>
            <gl-icon name="ellipsis_v" class="mr-0" />
            <span class="sr-only">{{ $options.i18n.optionsDropdownTitle }}</span>
          </template>
          <gl-dropdown-item ref="viewButton" :href="diffFile.view_path" target="_blank">
            {{ viewFileButtonText }}
          </gl-dropdown-item>
          <template v-if="showEditButton">
            <gl-dropdown-item
              v-if="diffFile.edit_path"
              ref="editButton"
              :href="diffFile.edit_path"
              class="js-edit-blob"
              @click="showForkMessage"
            >
              {{ __('Edit in single-file editor') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="diffFile.edit_path"
              ref="ideEditButton"
              :href="diffFile.ide_edit_path"
              class="js-ide-edit-blob"
              data-qa-selector="edit_in_ide_button"
              target="_blank"
            >
              {{ __('Open in Web IDE') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="showGenerateTestFileButton"
              @click="setGenerateTestFilePath(diffFile.new_path)"
            >
              <span class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
                {{ __('Suggest test cases') }}
                <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-n3" />
              </span>
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="diffFile.replaced_view_path"
              ref="replacedFileButton"
              :href="diffFile.replaced_view_path"
              target="_blank"
            >
              {{ viewReplacedFileButtonText }}
            </gl-dropdown-item>
          </template>

          <template v-if="!isCollapsed">
            <gl-dropdown-divider
              v-if="!diffFile.is_fully_expanded || diffHasDiscussions(diffFile)"
            />

            <gl-dropdown-item
              v-if="diffHasDiscussions(diffFile)"
              ref="toggleDiscussionsButton"
              data-qa-selector="toggle_comments_button"
              @click="toggleFileDiscussionWrappers(diffFile)"
            >
              <template v-if="diffHasExpandedDiscussions(diffFile)">
                {{ __('Hide comments on this file') }}
              </template>
              <template v-else>
                {{ __('Show comments on this file') }}
              </template>
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="!diffFile.is_fully_expanded"
              ref="expandDiffToFullFileButton"
              :disabled="diffFile.isLoadingFullFile"
              @click="toggleFullDiff(diffFile.file_path)"
            >
              <gl-loading-icon v-if="diffFile.isLoadingFullFile" size="sm" inline />
              {{ expandDiffToFullFileTitle }}
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </gl-button-group>
    </div>

    <div
      v-if="diffFile.submodule_compare"
      class="file-actions d-none d-sm-flex align-items-center flex-wrap"
    >
      <gl-button
        v-gl-tooltip.hover
        v-safe-html="submoduleDiffCompareLinkText"
        class="submodule-compare"
        :title="$options.i18n.compareButtonLabel"
        :aria-label="$options.i18n.compareButtonLabel"
        :href="diffFile.submodule_compare.url"
      />
    </div>
  </div>
</template>
