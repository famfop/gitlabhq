<script>
import { GlButton, GlLoadingIcon, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { updateText } from '~/lib/utils/text_markdown';
import { __, sprintf } from '~/locale';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import EditorModeSwitcher from './editor_mode_switcher.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlSprintf,
    GlIcon,
    EditorModeSwitcher,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    markdownDocsPath: {
      type: String,
      required: true,
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    showCommentToolBar: {
      type: Boolean,
      required: false,
      default: true,
    },
    showContentEditorSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showEditorModeSwitcher() {
      return this.showContentEditorSwitcher;
    },
  },
  methods: {
    insertIntoTextarea(...lines) {
      const text = lines.join('\n');
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
      if (textArea && !textArea.value) {
        updateText({
          textArea,
          tag: text,
          cursorOffset: 0,
          wrap: false,
        });
      }
    },
    handleEditorModeChanged(isFirstSwitch) {
      if (isFirstSwitch) {
        this.insertIntoTextarea(
          __(`### Rich text editor`),
          '',
          sprintf(
            __(
              'Try out **styling** _your_ content right here or read the [direction](%{directionUrl}).',
            ),
            {
              directionUrl: `${PROMO_URL}/direction/plan/knowledge/content_editor/`,
            },
          ),
        );
      }
      this.$emit('enableContentEditor');
    },
  },
};
</script>

<template>
  <div
    v-if="showCommentToolBar"
    class="comment-toolbar gl-display-flex gl-flex-direction-row gl-px-2 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
    :class="
      showContentEditorSwitcher
        ? 'gl-justify-content-space-between gl-align-items-center gl-border-t gl-border-gray-100'
        : 'gl-justify-content-end gl-my-2'
    "
  >
    <editor-mode-switcher
      v-if="showEditorModeSwitcher"
      size="small"
      value="markdown"
      @switch="handleEditorModeChanged"
    />
    <div class="gl-display-flex">
      <div v-if="canAttachFile" class="uploading-container gl-font-sm gl-line-height-32 gl-mr-3">
        <span class="uploading-progress-container hide">
          <gl-icon name="paperclip" />
          <span class="attaching-file-message"></span>
          <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
          <span class="uploading-progress">0%</span>
          <gl-loading-icon size="sm" inline />
        </span>
        <span class="uploading-error-container hide">
          <span class="uploading-error-icon">
            <gl-icon name="paperclip" />
          </span>
          <span class="uploading-error-message"></span>

          <gl-sprintf
            :message="
              __(
                '%{retryButtonStart}Try again%{retryButtonEnd} or %{newFileButtonStart}attach a new file%{newFileButtonEnd}.',
              )
            "
          >
            <template #retryButton="{ content }">
              <gl-button
                variant="link"
                category="primary"
                class="retry-uploading-link gl-vertical-align-baseline gl-font-sm!"
              >
                {{ content }}
              </gl-button>
            </template>
            <template #newFileButton="{ content }">
              <gl-button
                variant="link"
                category="primary"
                class="markdown-selector attach-new-file gl-vertical-align-baseline gl-font-sm!"
              >
                {{ content }}
              </gl-button>
            </template>
          </gl-sprintf>
        </span>
        <gl-button
          variant="link"
          category="primary"
          class="button-cancel-uploading-files gl-vertical-align-baseline hide gl-font-sm!"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
      <gl-button
        v-if="markdownDocsPath"
        v-gl-tooltip
        icon="markdown-mark"
        :href="markdownDocsPath"
        target="_blank"
        category="tertiary"
        size="small"
        title="Markdown is supported"
        class="gl-px-3!"
      />
    </div>
  </div>
</template>
