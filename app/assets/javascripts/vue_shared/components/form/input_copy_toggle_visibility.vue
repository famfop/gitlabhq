<script>
import {
  GlFormInputGroup,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';

import { __ } from '~/locale';
import { Mousetrap, MOUSETRAP_COPY_KEYBOARD_SHORTCUT } from '~/lib/mousetrap';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'InputCopyToggleVisibility',
  i18n: {
    toggleVisibilityLabelHide: __('Click to hide'),
    toggleVisibilityLabelReveal: __('Click to reveal'),
  },
  components: {
    GlFormInputGroup,
    GlFormInput,
    GlFormGroup,
    GlButton,
    ClipboardButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    initialVisibility: {
      type: Boolean,
      required: false,
      default: false,
    },
    showToggleVisibilityButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    showCopyButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    copyButtonTitle: {
      type: String,
      required: false,
      default: __('Copy'),
    },
    readonly: {
      type: Boolean,
      required: false,
      default: false,
    },
    formInputGroupProps: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    if (!this.readonly && !this.value) {
      return {
        valueIsVisible: true,
      };
    }

    return {
      valueIsVisible: this.initialVisibility,
    };
  },
  computed: {
    toggleVisibilityLabel() {
      return this.valueIsVisible
        ? this.$options.i18n.toggleVisibilityLabelHide
        : this.$options.i18n.toggleVisibilityLabelReveal;
    },
    toggleVisibilityIcon() {
      return this.valueIsVisible ? 'eye-slash' : 'eye';
    },
    computedValueIsVisible() {
      return !this.showToggleVisibilityButton || this.valueIsVisible;
    },
    inputType() {
      return this.computedValueIsVisible ? 'text' : 'password';
    },
  },
  mounted() {
    this.$options.mousetrap = new Mousetrap(this.$refs.input.$el);
    this.$options.mousetrap.bind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT, this.handleFormInputCopy);
  },
  beforeDestroy() {
    this.$options.mousetrap?.unbind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT);
  },

  methods: {
    handleToggleVisibilityButtonClick() {
      this.valueIsVisible = !this.valueIsVisible;

      this.$emit('visibility-change', this.valueIsVisible);
    },
    async handleClick() {
      if (this.readonly) {
        this.$refs.input.$el.select();
      } else if (!this.valueIsVisible) {
        const { selectionStart, selectionEnd } = this.$refs.input.$el;
        this.handleToggleVisibilityButtonClick();

        setTimeout(() => {
          // When the input type is changed from 'password'' to 'text', cursor position is reset in some browsers.
          // This makes clicking to edit difficult due to typing in unexpected location, so we preserve the cursor position / selection
          this.$refs.input.$el.setSelectionRange(selectionStart, selectionEnd);
        }, 0);
      }
    },
    handleCopyButtonClick() {
      this.$emit('copy');
    },
    async handleFormInputCopy() {
      // Value will be copied by native browser behavior
      if (this.computedValueIsVisible) {
        return;
      }

      try {
        // user is trying to copy from the password input, set their clipboard for them
        await navigator.clipboard?.writeText(this.value);
        this.handleCopyButtonClick();
      } catch (e) {
        // Nothing we can do here, best effort to set clipboard value
      }
    },
    handleInput(newValue) {
      this.$emit('input', newValue);
    },
  },
  mousetrap: null,
};
</script>
<template>
  <gl-form-group v-bind="$attrs">
    <gl-form-input-group>
      <gl-form-input
        ref="input"
        :readonly="readonly"
        class="gl-font-monospace! gl-cursor-default!"
        v-bind="formInputGroupProps"
        :value="value"
        :type="inputType"
        @input="handleInput"
        @click="handleClick"
      />

      <!--
        This v-if is necessary to avoid an issue with border radius.
        See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88059#note_969812649
       -->
      <template v-if="showToggleVisibilityButton || showCopyButton" #append>
        <gl-button
          v-if="showToggleVisibilityButton"
          v-gl-tooltip.hover="toggleVisibilityLabel"
          :aria-label="toggleVisibilityLabel"
          :icon="toggleVisibilityIcon"
          data-testid="toggle-visibility-button"
          data-qa-selector="toggle_visibility_button"
          @click.stop="handleToggleVisibilityButtonClick"
        />
        <clipboard-button
          v-if="showCopyButton"
          :text="value"
          :title="copyButtonTitle"
          data-qa-selector="clipboard_button"
          @click="handleCopyButtonClick"
        />
      </template>
    </gl-form-input-group>
    <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
    <template v-for="slot in Object.keys($slots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </gl-form-group>
</template>
