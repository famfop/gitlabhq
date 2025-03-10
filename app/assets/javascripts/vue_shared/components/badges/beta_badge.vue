<script>
import { GlBadge, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'BetaBadge',
  components: { GlBadge, GlPopover },
  i18n: {
    badgeLabel: s__('BetaBadge|Beta'),
    popoverTitle: s__("BetaBadge|What's Beta?"),
    descriptionParagraph: s__(
      "BetaBadge|A Beta feature is not production-ready, but is unlikely to change drastically before it's released. We encourage users to try Beta features and provide feedback.",
    ),
    listIntroduction: s__('BetaBadge|A Beta feature:'),
    listItemStability: s__('BetaBadge|May have performance or stability issues.'),
    listItemDataLoss: s__('BetaBadge|Should not cause data loss.'),
    listItemReasonableEffort: s__('BetaBadge|Is supported by a commercially reasonable effort.'),
    listItemNearCompletion: s__('BetaBadge|Is complete or near completion.'),
  },
  methods: {
    target() {
      /**
       * BVPopover retrieves the target during the `beforeDestroy` hook to deregister attached
       * events. Since during `beforeDestroy` refs are `undefined`, it throws a warning in the
       * console because we're trying to access the `$el` property of `undefined`. Optional
       * chaining is not working in templates, which is why the method is used.
       *
       * See more on https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49628#note_464803276
       */
      return this.$refs.badge?.$el;
    },
  },
};
</script>

<template>
  <div>
    <gl-badge ref="badge" class="gl-cursor-pointer">{{ $options.i18n.badgeLabel }}</gl-badge>
    <gl-popover
      triggers="hover focus click"
      :show-close-button="true"
      :target="target"
      :title="$options.i18n.popoverTitle"
      data-testid="beta-badge"
    >
      <p>{{ $options.i18n.descriptionParagraph }}</p>

      <p class="gl-mb-0">{{ $options.i18n.listIntroduction }}</p>

      <ul class="gl-pl-4">
        <li>{{ $options.i18n.listItemStability }}</li>
        <li>{{ $options.i18n.listItemDataLoss }}</li>
        <li>{{ $options.i18n.listItemReasonableEffort }}</li>
        <li>{{ $options.i18n.listItemNearCompletion }}</li>
      </ul>
    </gl-popover>
  </div>
</template>
