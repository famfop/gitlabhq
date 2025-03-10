<script>
import { GlAlert } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, n__, sprintf } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';
import { EVENT_ERROR, EVENT_SUCCESS, FORM_SELECTOR } from './constants';

const convertEventDetail = (event) => convertObjectPropsToCamelCase(event.detail, { deep: true });

export default {
  EVENT_ERROR,
  EVENT_SUCCESS,
  FORM_SELECTOR,
  name: 'NewAccessTokenApp',
  components: { DomElementListener, GlAlert, InputCopyToggleVisibility },
  i18n: {
    alertInfoMessage: __('Your new %{accessTokenType} has been created.'),
    copyButtonTitle: __('Copy %{accessTokenType}'),
    description: __("Make sure you save it - you won't be able to access it again."),
    label: __('Your new %{accessTokenType}'),
  },
  tokenInputId: 'new-access-token',
  inject: ['accessTokenType'],
  data() {
    return { errors: null, infoAlert: null, newToken: null };
  },
  computed: {
    alertInfoMessage() {
      return sprintf(this.$options.i18n.alertInfoMessage, {
        accessTokenType: this.accessTokenType,
      });
    },
    alertDangerTitle() {
      return n__(
        'The form contains the following error:',
        'The form contains the following errors:',
        this.errors?.length ?? 0,
      );
    },
    copyButtonTitle() {
      return sprintf(this.$options.i18n.copyButtonTitle, { accessTokenType: this.accessTokenType });
    },
    formInputGroupProps() {
      return {
        id: this.$options.tokenInputId,
        'data-qa-selector': 'created_access_token_field',
        name: this.$options.tokenInputId,
      };
    },
    label() {
      return sprintf(this.$options.i18n.label, { accessTokenType: this.accessTokenType });
    },
  },
  mounted() {
    /** @type {HTMLFormElement} */
    this.form = document.querySelector(FORM_SELECTOR);

    /** @type {HTMLButtonElement} */
    this.submitButton = this.form.querySelector('[type=submit]');
  },
  methods: {
    beforeDisplayResults() {
      this.infoAlert?.dismiss();
      this.$refs.container.scrollIntoView(false);

      this.errors = null;
      this.newToken = null;
    },
    onError(event) {
      this.beforeDisplayResults();

      const [{ errors }] = convertEventDetail(event);
      this.errors = errors;

      this.submitButton.classList.remove('disabled');
      this.submitButton.removeAttribute('disabled');
    },
    onSuccess(event) {
      this.beforeDisplayResults();

      const [{ newToken }] = convertEventDetail(event);
      this.newToken = newToken;

      this.infoAlert = createAlert({ message: this.alertInfoMessage, variant: VARIANT_INFO });

      // Selectively reset all input fields except for the date picker.
      // The form token creation is not controlled by Vue.
      this.form.querySelectorAll('input[type=text]:not([id$=expires_at])').forEach((el) => {
        el.value = '';
      });
      this.form.querySelectorAll('input[type=checkbox]').forEach((el) => {
        el.checked = false;
      });
    },
  },
};
</script>

<template>
  <dom-element-listener
    :selector="$options.FORM_SELECTOR"
    @[$options.EVENT_ERROR]="onError"
    @[$options.EVENT_SUCCESS]="onSuccess"
  >
    <div ref="container" data-testid="access-token-section" data-qa-selector="access_token_section">
      <template v-if="newToken">
        <input-copy-toggle-visibility
          :copy-button-title="copyButtonTitle"
          :label="label"
          :label-for="$options.tokenInputId"
          :value="newToken"
          :form-input-group-props="formInputGroupProps"
          readonly
        >
          <template #description>
            {{ $options.i18n.description }}
          </template>
        </input-copy-toggle-visibility>
        <hr />
      </template>

      <template v-if="errors">
        <gl-alert :title="alertDangerTitle" variant="danger" @dismiss="errors = null">
          <ul class="gl-m-0">
            <li v-for="error in errors" :key="error">
              {{ error }}
            </li>
          </ul>
        </gl-alert>
        <hr />
      </template>
    </div>
  </dom-element-listener>
</template>
