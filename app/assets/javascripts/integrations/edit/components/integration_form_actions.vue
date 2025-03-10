<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { integrationLevels } from '~/integrations/constants';
import ConfirmationModal from './confirmation_modal.vue';
import ResetConfirmationModal from './reset_confirmation_modal.vue';

export default {
  name: 'IntegrationFormActions',
  components: {
    GlButton,
    ConfirmationModal,
    ResetConfirmationModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    hasSections: {
      type: Boolean,
      required: true,
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    isTesting: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResetting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['propsSource']),
    ...mapState(['customState']),
    isInstanceOrGroupLevel() {
      return (
        this.customState.integrationLevel === integrationLevels.INSTANCE ||
        this.customState.integrationLevel === integrationLevels.GROUP
      );
    },
    showResetButton() {
      return this.isInstanceOrGroupLevel && this.propsSource.resetPath;
    },
    showTestButton() {
      return this.propsSource.canTest;
    },
    disableButtons() {
      return Boolean(this.isSaving || this.isResetting || this.isTesting);
    },
  },
  methods: {
    onSaveClick() {
      this.$emit('save');
    },
    onTestClick() {
      this.$emit('test');
    },
    onResetClick() {
      this.$emit('reset');
    },
  },
};
</script>
<template>
  <section class="gl-lg-display-flex gl-justify-content-space-between">
    <div>
      <template v-if="isInstanceOrGroupLevel">
        <gl-button
          v-gl-modal.confirmSaveIntegration
          category="primary"
          variant="confirm"
          :loading="isSaving"
          :disabled="disableButtons"
          data-testid="save-button"
          data-qa-selector="save_changes_button"
        >
          {{ __('Save changes') }}
        </gl-button>
        <confirmation-modal @submit="onSaveClick" />
      </template>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        type="submit"
        :loading="isSaving"
        :disabled="disableButtons"
        data-testid="save-button"
        data-qa-selector="save_changes_button"
        @click.prevent="onSaveClick"
      >
        {{ __('Save changes') }}
      </gl-button>

      <gl-button
        v-if="showTestButton"
        category="secondary"
        variant="confirm"
        :loading="isTesting"
        :disabled="disableButtons"
        data-testid="test-button"
        @click.prevent="onTestClick"
      >
        {{ __('Test settings') }}
      </gl-button>

      <gl-button
        :href="propsSource.cancelPath"
        data-testid="cancel-button"
        :disabled="disableButtons"
        >{{ __('Cancel') }}</gl-button
      >
    </div>

    <template v-if="showResetButton">
      <gl-button
        v-gl-modal.confirmResetIntegration
        category="tertiary"
        variant="danger"
        :loading="isResetting"
        :disabled="disableButtons"
        data-testid="reset-button"
      >
        {{ __('Reset') }}
      </gl-button>

      <reset-confirmation-modal @reset="onResetClick" />
    </template>
  </section>
</template>
