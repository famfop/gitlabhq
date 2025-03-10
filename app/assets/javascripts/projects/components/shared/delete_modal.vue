<script>
import { GlModal, GlAlert, GlSprintf, GlFormInput } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __ } from '~/locale';

export default {
  i18n: {
    deleteProject: __('Delete project'),
    title: __('Are you absolutely sure?'),
    confirmText: __('Enter the following to confirm:'),
    isForkAlertTitle: __('You are about to delete this forked project containing:'),
    isNotForkAlertTitle: __('You are about to delete this project containing:'),
    isForkAlertBody: __('This process deletes the project repository and all related resources.'),
    isNotForkAlertBody: __(
      'This project is %{strongStart}NOT%{strongEnd} a fork. This process deletes the project repository and all related resources.',
    ),
    isNotForkMessage: __(
      'This project is %{strongStart}NOT%{strongEnd} a fork, and has the following:',
    ),
  },
  components: { GlModal, GlAlert, GlSprintf, GlFormInput },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    issuesCount: {
      type: Number,
      required: false,
      default: null,
    },
    mergeRequestsCount: {
      type: Number,
      required: false,
      default: null,
    },
    forksCount: {
      type: Number,
      required: false,
      default: null,
    },
    starsCount: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      userInput: null,
      modalId: uniqueId('delete-project-modal-'),
    };
  },
  computed: {
    confirmDisabled() {
      return this.userInput !== this.confirmPhrase;
    },
    modalActionProps() {
      return {
        primary: {
          text: __('Yes, delete project'),
          attributes: {
            variant: 'danger',
            disabled: this.confirmDisabled,
            'data-qa-selector': 'confirm_delete_button',
          },
        },
        cancel: {
          text: __('Cancel, keep project'),
        },
      };
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    footer-class="gl-bg-gray-10 gl-p-5"
    title-class="gl-text-red-500"
    :action-primary="modalActionProps.primary"
    :action-cancel="modalActionProps.cancel"
    @primary="$emit('primary', $event)"
    @change="$emit('change', $event)"
  >
    <template #modal-title>{{ $options.i18n.title }}</template>
    <div>
      <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
        <h4 v-if="isFork" data-testid="delete-alert-title" class="gl-alert-title">
          {{ $options.i18n.isForkAlertTitle }}
        </h4>
        <h4 v-else data-testid="delete-alert-title" class="gl-alert-title">
          {{ $options.i18n.isNotForkAlertTitle }}
        </h4>
        <ul>
          <li v-if="issuesCount !== null">
            <gl-sprintf :message="n__('%d issue', '%d issues', issuesCount)">
              <template #issuesCount>{{ issuesCount }}</template>
            </gl-sprintf>
          </li>
          <li v-if="mergeRequestsCount !== null">
            <gl-sprintf
              :message="n__('%d merge requests', '%d merge requests', mergeRequestsCount)"
            >
              <template #mergeRequestsCount>{{ mergeRequestsCount }}</template>
            </gl-sprintf>
          </li>
          <li v-if="forksCount !== null">
            <gl-sprintf :message="n__('%d fork', '%d forks', forksCount)">
              <template #forksCount>{{ forksCount }}</template>
            </gl-sprintf>
          </li>
          <li v-if="starsCount !== null">
            <gl-sprintf :message="n__('%d star', '%d stars', starsCount)">
              <template #starsCount>{{ starsCount }}</template>
            </gl-sprintf>
          </li>
        </ul>
        <gl-sprintf
          v-if="isFork"
          data-testid="delete-alert-body"
          :message="$options.i18n.isForkAlertBody"
        />
        <gl-sprintf
          v-else
          data-testid="delete-alert-body"
          :message="$options.i18n.isNotForkAlertBody"
        >
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>
      <p class="gl-mb-1">{{ $options.i18n.confirmText }}</p>
      <p>
        <code class="gl-white-space-pre-wrap">{{ confirmPhrase }}</code>
      </p>

      <gl-form-input
        id="confirm_name_input"
        v-model="userInput"
        name="confirm_name_input"
        type="text"
        data-qa-selector="confirm_name_field"
      />
      <slot name="modal-footer"></slot>
    </div>
  </gl-modal>
</template>
