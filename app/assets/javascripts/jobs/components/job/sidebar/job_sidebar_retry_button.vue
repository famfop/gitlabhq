<script>
import { GlButton, GlDisclosureDropdown, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR_COPY } from '~/jobs/constants';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    ...JOB_SIDEBAR_COPY,
  },
  components: {
    GlButton,
    GlDisclosureDropdown,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
    isManualJob: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.runAgainJobButtonLabel,
          href: this.href,
          extraAttrs: {
            'data-method': 'post',
          },
        },
        {
          text: this.$options.i18n.updateVariables,
          action: () => this.$emit('updateVariablesClicked'),
        },
      ];
    },
  },
};
</script>
<template>
  <gl-button
    v-if="hasForwardDeploymentFailure"
    v-gl-modal="modalId"
    :aria-label="$options.i18n.retryJobLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-testid="retry-job-button"
  />
  <gl-disclosure-dropdown
    v-else-if="isManualJob"
    icon="retry"
    category="primary"
    placement="right"
    variant="confirm"
    :items="dropdownItems"
  />
  <gl-button
    v-else
    :href="href"
    :aria-label="$options.i18n.retryJobLabel"
    category="primary"
    variant="confirm"
    icon="retry"
    data-method="post"
    data-testid="retry-job-link"
  />
</template>
