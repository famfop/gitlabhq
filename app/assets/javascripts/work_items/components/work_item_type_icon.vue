<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { WORK_ITEMS_TYPE_MAP } from '../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    showText: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIconName: {
      type: String,
      required: false,
      default: '',
    },
    showTooltipOnHover: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    iconName() {
      return (
        this.workItemIconName || WORK_ITEMS_TYPE_MAP[this.workItemType]?.icon || 'issue-type-issue'
      );
    },
    workItemTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.workItemType]?.name;
    },
    workItemTooltipTitle() {
      return this.showTooltipOnHover ? this.workItemTypeName : '';
    },
  },
};
</script>

<template>
  <span class="gl-mr-2">
    <gl-icon
      v-gl-tooltip.hover="showTooltipOnHover"
      :name="iconName"
      :title="workItemTooltipTitle"
      class="gl-text-secondary"
    />
    <span v-if="workItemTypeName" :class="{ 'gl-sr-only': !showText }">{{ workItemTypeName }}</span>
  </span>
</template>
