<script>
import { GlButton } from '@gitlab/ui';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, TOGGLE_SUPER_SIDEBAR } from '~/behaviors/shortcuts/keybindings';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { sidebarState } from '../constants';
import { isCollapsed, toggleSuperSidebarCollapsed } from '../super_sidebar_collapsed_state_manager';
import UserBar from './user_bar.vue';
import SidebarPortalTarget from './sidebar_portal_target.vue';
import ContextHeader from './context_header.vue';
import ContextSwitcher from './context_switcher.vue';
import HelpCenter from './help_center.vue';
import SidebarMenu from './sidebar_menu.vue';
import SidebarPeekBehavior, { STATE_CLOSED, STATE_WILL_OPEN } from './sidebar_peek_behavior.vue';

export default {
  components: {
    GlButton,
    UserBar,
    ContextHeader,
    ContextSwitcher,
    HelpCenter,
    SidebarMenu,
    SidebarPeekBehavior,
    SidebarPortalTarget,
    TrialStatusWidget: () =>
      import('ee_component/contextual_sidebar/components/trial_status_widget.vue'),
    TrialStatusPopover: () =>
      import('ee_component/contextual_sidebar/components/trial_status_popover.vue'),
  },
  mixins: [Tracking.mixin()],
  i18n: {
    skipToMainContent: __('Skip to main content'),
  },
  inject: ['showTrialStatusWidget'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      sidebarState,
      showPeekHint: false,
      isMouseover: false,
    };
  },
  computed: {
    menuItems() {
      return this.sidebarData.current_menu_items || [];
    },
    peekClasses() {
      return {
        'super-sidebar-peek-hint': this.showPeekHint,
        'super-sidebar-peek': this.sidebarState.isPeek,
      };
    },
  },
  watch: {
    'sidebarState.isCollapsed': function isCollapsedWatcher(newIsCollapsed) {
      if (newIsCollapsed && this.$refs['context-switcher']) {
        this.$refs['context-switcher'].close();
      }
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(TOGGLE_SUPER_SIDEBAR), this.toggleSidebar);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(TOGGLE_SUPER_SIDEBAR));
  },
  methods: {
    toggleSidebar() {
      this.track(isCollapsed() ? 'nav_show' : 'nav_hide', {
        label: 'nav_toggle_keyboard_shortcut',
        property: 'nav_sidebar',
      });
      toggleSuperSidebarCollapsed(!isCollapsed(), true);
    },
    collapseSidebar() {
      toggleSuperSidebarCollapsed(true, false);
    },
    onPeekChange(state) {
      if (state === STATE_CLOSED) {
        this.sidebarState.isPeek = false;
        this.sidebarState.isCollapsed = true;
        this.showPeekHint = false;
      } else if (state === STATE_WILL_OPEN) {
        this.sidebarState.isPeek = false;
        this.sidebarState.isCollapsed = true;
        this.showPeekHint = true;
      } else {
        this.sidebarState.isPeek = true;
        this.sidebarState.isCollapsed = false;
        this.showPeekHint = false;
      }
    },
    onContextSwitcherToggled(open) {
      this.sidebarState.contextSwitcherOpen = open;
    },
  },
};
</script>

<template>
  <div>
    <div class="super-sidebar-overlay" @click="collapseSidebar"></div>
    <gl-button
      class="super-sidebar-skip-to gl-sr-only-focusable gl-fixed gl-left-0 gl-m-3"
      href="#content-body"
      variant="confirm"
    >
      {{ $options.i18n.skipToMainContent }}
    </gl-button>
    <aside
      id="super-sidebar"
      class="super-sidebar"
      :class="peekClasses"
      data-testid="super-sidebar"
      data-qa-selector="navbar"
      :inert="sidebarState.isCollapsed"
      @mouseenter="isMouseover = true"
      @mouseleave="isMouseover = false"
    >
      <user-bar :has-collapse-button="!sidebarState.isPeek" :sidebar-data="sidebarData" />
      <div v-if="showTrialStatusWidget" class="gl-px-2 gl-py-2">
        <trial-status-widget
          class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-px-3 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none! nav-item-link gl-py-3"
        />
        <trial-status-popover />
      </div>
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
        <div
          class="gl-flex-grow-1"
          :class="{ 'gl-overflow-auto': !sidebarState.contextSwitcherOpen }"
          data-testid="nav-container"
        >
          <context-switcher
            v-if="sidebarData.is_logged_in"
            ref="context-switcher"
            :persistent-links="sidebarData.context_switcher_links"
            :username="sidebarData.username"
            :projects-path="sidebarData.projects_path"
            :groups-path="sidebarData.groups_path"
            :current-context="sidebarData.current_context"
            :context-header="sidebarData.current_context_header"
            @toggle="onContextSwitcherToggled"
          />
          <context-header v-else :context="sidebarData.current_context_header" />
          <sidebar-menu
            v-if="menuItems.length"
            :items="menuItems"
            :is-logged-in="sidebarData.is_logged_in"
            :panel-type="sidebarData.panel_type"
            :pinned-item-ids="sidebarData.pinned_items"
            :update-pins-url="sidebarData.update_pins_url"
          />
          <sidebar-portal-target />
        </div>
        <div class="gl-p-3">
          <help-center :sidebar-data="sidebarData" />
        </div>
      </div>
    </aside>
    <a
      v-for="shortcutLink in sidebarData.shortcut_links"
      :key="shortcutLink.href"
      :href="shortcutLink.href"
      :class="shortcutLink.css_class"
      class="gl-display-none"
    >
      {{ shortcutLink.title }}
    </a>

    <!--
      Only mount SidebarPeekBehavior if the sidebar is peekable, to avoid
      setting up event listeners unnecessarily.
    -->
    <sidebar-peek-behavior
      v-if="sidebarState.isPeekable"
      :is-mouse-over-sidebar="isMouseover"
      @change="onPeekChange"
    />
  </div>
</template>
