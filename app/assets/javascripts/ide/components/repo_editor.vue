<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapState, mapGetters, mapActions } from 'vuex';
import {
  EDITOR_TYPE_DIFF,
  EDITOR_TYPE_CODE,
  EDITOR_CODE_INSTANCE_FN,
  EDITOR_DIFF_INSTANCE_FN,
  EXTENSION_CI_SCHEMA_FILE_NAME_MATCH,
} from '~/editor/constants';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { EditorWebIdeExtension } from '~/editor/extensions/source_editor_webide_ext';
import SourceEditor from '~/editor/source_editor';
import { createAlert } from '~/alert';
import ModelManager from '~/ide/lib/common/model_manager';
import { defaultDiffEditorOptions, defaultEditorOptions } from '~/ide/lib/editor_options';
import { __ } from '~/locale';
import {
  WEBIDE_MARK_FILE_CLICKED,
  WEBIDE_MARK_REPO_EDITOR_START,
  WEBIDE_MARK_REPO_EDITOR_FINISH,
  WEBIDE_MEASURE_REPO_EDITOR,
  WEBIDE_MEASURE_FILE_AFTER_INTERACTION,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import { viewerInformationForPath } from '~/vue_shared/components/content_viewer/lib/viewer_utils';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';
import { readFileAsDataURL } from '~/lib/utils/file_utility';

import {
  leftSidebarViews,
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
} from '../constants';
import eventHub from '../eventhub';
import { getRulesWithTraversal } from '../lib/editorconfig/parser';
import mapRulesToMonaco from '../lib/editorconfig/rules_mapper';
import { getFileEditorOrDefault } from '../stores/modules/editor/utils';
import { extractMarkdownImagesFromEntries } from '../stores/utils';
import { getPathParent, registerSchema, isTextFile } from '../utils';
import FileAlert from './file_alert.vue';
import FileTemplatesBar from './file_templates/bar.vue';

const MARKDOWN_FILE_TYPE = 'markdown';

export default {
  name: 'RepoEditor',
  components: {
    GlTabs,
    GlTab,
    FileAlert,
    ContentViewer,
    DiffViewer,
    FileTemplatesBar,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      content: '',
      images: {},
      rules: {},
      globalEditor: null,
      modelManager: markRaw(new ModelManager()),
      isEditorLoading: true,
      unwatchCiYaml: null,
      SELivepreviewExtension: null,
      MarkdownLivePreview: null,
    };
  },
  computed: {
    ...mapState('rightPane', {
      rightPaneIsOpen: 'isOpen',
    }),
    ...mapState('editor', ['fileEditors']),
    ...mapState([
      'viewer',
      'panelResizing',
      'currentActivityView',
      'renderWhitespaceInCode',
      'editorTheme',
      'entries',
      'currentProjectId',
      'previewMarkdownPath',
    ]),
    ...mapGetters([
      'getAlert',
      'currentMergeRequest',
      'getStagedFile',
      'isEditModeActive',
      'isCommitModeActive',
      'currentBranch',
      'getJsonSchemaForPath',
    ]),
    ...mapGetters('fileTemplates', ['showFileTemplatesBar']),
    alertKey() {
      return this.getAlert(this.file);
    },
    fileEditor() {
      return getFileEditorOrDefault(this.fileEditors, this.file.path);
    },
    isBinaryFile() {
      return !isTextFile(this.file);
    },
    shouldHideEditor() {
      return this.file && !this.file.loading && this.isBinaryFile;
    },
    showContentViewer() {
      return (
        (this.shouldHideEditor || this.isPreviewViewMode) &&
        (this.viewer !== viewerTypes.mr || !this.file.mrChange)
      );
    },
    showDiffViewer() {
      return this.shouldHideEditor && this.file.mrChange && this.viewer === viewerTypes.mr;
    },
    isEditorViewMode() {
      return this.fileEditor.viewMode === FILE_VIEW_MODE_EDITOR;
    },
    isPreviewViewMode() {
      return this.fileEditor.viewMode === FILE_VIEW_MODE_PREVIEW;
    },
    showEditor() {
      return !this.shouldHideEditor && this.isEditorViewMode;
    },
    editorOptions() {
      return {
        renderWhitespace: this.renderWhitespaceInCode ? 'all' : 'none',
        theme: this.editorTheme,
      };
    },
    currentBranchCommit() {
      return this.currentBranch?.commit.id;
    },
    previewMode() {
      return viewerInformationForPath(this.file.path);
    },
    fileType() {
      return this.previewMode?.id || '';
    },
    showTabs() {
      return !this.shouldHideEditor && this.isEditModeActive && this.previewMode;
    },
    isCiConfigFile() {
      return (
        this.file.path === EXTENSION_CI_SCHEMA_FILE_NAME_MATCH &&
        this.editor?.getEditorType() === EDITOR_TYPE_CODE
      );
    },
  },
  watch: {
    'file.name': {
      handler() {
        this.stopWatchingCiYaml();

        if (this.file.name === '.gitlab-ci.yml') {
          this.startWatchingCiYaml();
        }
      },
      immediate: true,
    },
    file(newVal, oldVal) {
      if (oldVal.pending) {
        this.removePendingTab(oldVal);
      }

      // Compare key to allow for files opened in review mode to be cached differently
      if (oldVal.key !== this.file.key) {
        this.isEditorLoading = true;
        this.initEditor();

        if (this.currentActivityView !== leftSidebarViews.edit.name) {
          this.updateEditor({
            viewMode: FILE_VIEW_MODE_EDITOR,
          });
        }
      }
    },
    currentActivityView() {
      if (this.currentActivityView !== leftSidebarViews.edit.name) {
        this.updateEditor({
          viewMode: FILE_VIEW_MODE_EDITOR,
        });
      }
    },
    viewer() {
      this.isEditorLoading = false;
      if (!this.file.pending) {
        this.createEditorInstance();
      }
    },
    showContentViewer(val) {
      if (!val) return;

      if (this.fileType === MARKDOWN_FILE_TYPE) {
        const { content, images } = extractMarkdownImagesFromEntries(this.file, this.entries);
        this.content = content;
        this.images = images;
      } else {
        this.content = this.file.content || this.file.raw;
        this.images = {};
      }
    },
  },
  beforeDestroy() {
    this.globalEditor.dispose();
  },
  mounted() {
    if (!this.globalEditor) {
      this.globalEditor = markRaw(new SourceEditor());
    }
    this.initEditor();

    // listen in capture phase to be able to override Monaco's behaviour.
    window.addEventListener('paste', this.onPaste, true);
  },
  destroyed() {
    window.removeEventListener('paste', this.onPaste, true);
  },
  methods: {
    ...mapActions([
      'getFileData',
      'getRawFileData',
      'changeFileContent',
      'removePendingTab',
      'triggerFilesChange',
      'addTempImage',
      'detectGitlabCiFileAlerts',
    ]),
    ...mapActions('editor', ['updateFileEditor']),
    initEditor() {
      performanceMarkAndMeasure({ mark: WEBIDE_MARK_REPO_EDITOR_START });
      if (this.shouldHideEditor && (this.file.content || this.file.raw)) {
        return;
      }

      Promise.all([this.fetchFileData(), this.fetchEditorconfigRules()])
        .then(() => {
          this.createEditorInstance();
        })
        .catch((err) => {
          createAlert({
            message: __('Error setting up editor. Please try again.'),
            fadeTransition: false,
            addBodyClass: true,
          });
          throw err;
        });
    },
    fetchFileData() {
      if (this.file.tempFile) {
        return Promise.resolve();
      }

      return this.getFileData({
        path: this.file.path,
        makeFileActive: false,
        toggleLoading: false,
      }).then(() =>
        this.getRawFileData({
          path: this.file.path,
        }),
      );
    },
    createEditorInstance() {
      if (this.isBinaryFile) {
        return;
      }

      const isDiff = this.viewer !== viewerTypes.edit;
      const shouldDisposeEditor = isDiff !== (this.editor?.getEditorType() === EDITOR_TYPE_DIFF);

      if (this.editor && !shouldDisposeEditor) {
        this.setupEditor();
      } else {
        if (this.editor && shouldDisposeEditor) {
          this.editor.dispose();
        }
        const instanceOptions = isDiff ? defaultDiffEditorOptions : defaultEditorOptions;
        const method = isDiff ? EDITOR_DIFF_INSTANCE_FN : EDITOR_CODE_INSTANCE_FN;

        this.editor = markRaw(
          this.globalEditor[method]({
            el: this.$refs.editor,
            blobPath: this.file.path,
            blobGlobalId: this.file.key,
            blobContent: this.content || this.file.content,
            ...instanceOptions,
            ...this.editorOptions,
          }),
        );
        this.editor.use([
          {
            definition: SourceEditorExtension,
          },
          {
            definition: EditorWebIdeExtension,
            setupOptions: {
              modelManager: this.modelManager,
              store: this.$store,
              file: this.file,
              options: this.editorOptions,
            },
          },
        ]);

        this.$nextTick(() => {
          this.setupEditor();
        });
      }
    },

    setupEditor() {
      if (!this.file || !this.editor || this.file.loading) return;

      const useLivePreviewExtension = () => {
        this.SELivepreviewExtension = this.editor.use({
          definition: this.MarkdownLivePreview,
          setupOptions: { previewMarkdownPath: this.previewMarkdownPath },
        });
      };
      if (
        this.fileType === MARKDOWN_FILE_TYPE &&
        this.editor?.getEditorType() === EDITOR_TYPE_CODE &&
        this.previewMarkdownPath
      ) {
        if (this.MarkdownLivePreview) {
          useLivePreviewExtension();
        } else {
          import('~/editor/extensions/source_editor_markdown_livepreview_ext')
            .then(({ EditorMarkdownPreviewExtension }) => {
              this.MarkdownLivePreview = EditorMarkdownPreviewExtension;
              useLivePreviewExtension();
            })
            .catch((e) =>
              createAlert({
                message: e,
              }),
            );
        }
      } else if (this.SELivepreviewExtension) {
        this.editor.unuse(this.SELivepreviewExtension);
      }

      const head = this.getStagedFile(this.file.path);

      this.model = this.editor.createModel(
        this.file,
        this.file.staged && this.file.key.indexOf('unstaged-') === 0 ? head : null,
      );

      if (this.viewer === viewerTypes.mr && this.file.mrChange) {
        this.editor.attachMergeRequestModel(this.model);
      } else {
        this.editor.attachModel(this.model);
      }

      this.isEditorLoading = false;

      this.model.updateOptions(this.rules);

      this.registerSchemaForFile();

      this.model.onChange((model) => {
        const { file } = model;
        if (!file.active) return;

        const monacoModel = model.getModel();
        const content = monacoModel.getValue();
        this.changeFileContent({ path: file.path, content });
      });

      // Handle Cursor Position
      this.editor.onPositionChange((instance, e) => {
        this.updateEditor({
          editorRow: e.position.lineNumber,
          editorColumn: e.position.column,
        });
      });

      this.editor.setPos({
        lineNumber: this.fileEditor.editorRow,
        column: this.fileEditor.editorColumn,
      });

      // Handle File Language
      this.updateEditor({
        fileLanguage: this.model.language,
      });

      this.$emit('editorSetup');
      if (performance.getEntriesByName(WEBIDE_MARK_FILE_CLICKED).length) {
        eventHub.$emit(WEBIDE_MEASURE_FILE_AFTER_INTERACTION);
      } else {
        performanceMarkAndMeasure({
          mark: WEBIDE_MARK_REPO_EDITOR_FINISH,
          measures: [
            {
              name: WEBIDE_MEASURE_REPO_EDITOR,
              start: WEBIDE_MARK_REPO_EDITOR_START,
            },
          ],
        });
      }
    },
    fetchEditorconfigRules() {
      return getRulesWithTraversal(this.file.path, (path) => {
        const entry = this.entries[path];
        if (!entry) return Promise.resolve(null);

        const content = entry.content || entry.raw;
        if (content) return Promise.resolve(content);

        return this.getFileData({ path: entry.path, makeFileActive: false }).then(() =>
          this.getRawFileData({ path: entry.path }),
        );
      }).then((rules) => {
        this.rules = mapRulesToMonaco(rules);
      });
    },
    onPaste(event) {
      const { editor } = this;
      const reImage = /^image\/(png|jpg|jpeg|gif)$/;
      const file = event.clipboardData.files[0];

      if (
        editor.hasTextFocus() &&
        this.fileType === MARKDOWN_FILE_TYPE &&
        reImage.test(file?.type)
      ) {
        // don't let the event be passed on to Monaco.
        event.preventDefault();
        event.stopImmediatePropagation();

        return readFileAsDataURL(file).then((content) => {
          const parentPath = getPathParent(this.file.path);
          const path = `${parentPath ? `${parentPath}/` : ''}${file.name}`;

          return this.addTempImage({
            name: path,
            rawPath: URL.createObjectURL(file),
            content: atob(content.split('base64,')[1]),
          }).then(({ name: fileName }) => {
            this.editor.replaceSelectedText(`![${fileName}](./${fileName})`);
          });
        });
      }

      // do nothing if no image is found in the clipboard
      return Promise.resolve();
    },
    registerSchemaForFile() {
      const registerExternalSchema = () => {
        const schema = this.getJsonSchemaForPath(this.file.path);
        return registerSchema(schema);
      };
      const registerLocalSchema = async () => {
        if (!this.CiSchemaExtension) {
          const { CiSchemaExtension } = await import(
            '~/editor/extensions/source_editor_ci_schema_ext'
          ).catch((e) =>
            createAlert({
              message: e,
            }),
          );
          this.CiSchemaExtension = CiSchemaExtension;
        }
        this.editor.use({ definition: this.CiSchemaExtension });
        this.editor.registerCiSchema();
      };

      if (this.isCiConfigFile) {
        registerLocalSchema();
      } else {
        if (this.CiSchemaExtension) {
          this.editor.unuse(this.CiSchemaExtension);
        }
        registerExternalSchema();
      }
    },
    updateEditor(data) {
      // Looks like our model wrapper `.dispose` causes the monaco editor to emit some position changes after
      // when disposing. We want to ignore these by only capturing editor changes that happen to the currently active
      // file.
      if (!this.file.active) {
        return;
      }

      this.updateFileEditor({ path: this.file.path, data });
    },
    startWatchingCiYaml() {
      this.unwatchCiYaml = this.$watch(
        'file.content',
        debounce(this.detectGitlabCiFileAlerts, 500),
      );
    },
    stopWatchingCiYaml() {
      if (this.unwatchCiYaml) {
        this.unwatchCiYaml();
        this.unwatchCiYaml = null;
      }
    },
  },
  viewerTypes,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
};
</script>

<template>
  <div id="ide" class="blob-viewer-container blob-editor-container">
    <gl-tabs v-if="showTabs" content-class="gl-display-none">
      <gl-tab
        :title="__('Edit')"
        data-testid="edit-tab"
        @click="updateEditor({ viewMode: $options.FILE_VIEW_MODE_EDITOR })"
      />
      <gl-tab
        :title="previewMode.previewTitle"
        data-testid="preview-tab"
        @click="updateEditor({ viewMode: $options.FILE_VIEW_MODE_PREVIEW })"
      />
    </gl-tabs>
    <file-alert v-if="alertKey" :alert-key="alertKey" />
    <file-templates-bar v-else-if="showFileTemplatesBar(file.name)" />
    <div
      v-show="showEditor"
      ref="editor"
      :key="`content-editor`"
      :class="{
        'is-readonly': isCommitModeActive,
        'is-deleted': file.deleted,
        'is-added': file.tempFile,
      }"
      class="multi-file-editor-holder"
      data-qa-selector="editor_container"
      data-testid="editor-container"
      :data-editor-loading="isEditorLoading"
      @focusout="triggerFilesChange"
    ></div>
    <content-viewer
      v-if="showContentViewer"
      :content="content"
      :images="images"
      :path="file.rawPath || file.path"
      :file-path="file.path"
      :file-size="file.size"
      :project-path="currentProjectId"
      :commit-sha="currentBranchCommit"
      :type="fileType"
    />
    <diff-viewer
      v-if="showDiffViewer"
      :diff-mode="file.mrChange.diffMode"
      :new-path="file.mrChange.new_path"
      :new-sha="currentMergeRequest.sha"
      :old-path="file.mrChange.old_path"
      :old-sha="currentMergeRequest.baseCommitSha"
      :project-path="currentProjectId"
    />
  </div>
</template>
