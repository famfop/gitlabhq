<script>
import { GlIcon, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { findLastIndex } from 'lodash';
import VirtualList from 'vue-virtual-scroll-list';
import { CATEGORY_NAMES, getEmojiCategoryMap, state } from '~/emoji';
import { CATEGORY_ICON_MAP, FREQUENTLY_USED_KEY } from '../constants';
import Category from './category.vue';
import EmojiList from './emoji_list.vue';
import { addToFrequentlyUsed, getEmojiCategories, hasFrequentlyUsedEmojis } from './utils';

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlSearchBoxByType,
    VirtualList,
    Category,
    EmojiList,
  },
  props: {
    toggleClass: {
      type: [Array, String, Object],
      required: false,
      default: () => [],
    },
    dropdownClass: {
      type: [Array, String, Object],
      required: false,
      default: () => [],
    },
    right: {
      type: Boolean,
      required: false,
      default: true,
    },
    boundary: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      currentCategory: 0,
      searchValue: '',
    };
  },
  computed: {
    categoryNames() {
      return CATEGORY_NAMES.filter((c) => {
        if (c === FREQUENTLY_USED_KEY) return hasFrequentlyUsedEmojis();
        if (c === 'custom') return !state.loading && getEmojiCategoryMap().custom.length > 0;
        return true;
      }).map((category) => ({
        name: category,
        icon: CATEGORY_ICON_MAP[category],
      }));
    },
  },
  methods: {
    categoryAppeared(category) {
      this.currentCategory = category;
    },
    async scrollToCategory(categoryName) {
      const categories = await getEmojiCategories();
      const { top } = categories[categoryName];

      this.$refs.virtualScoller.setScrollTop(top);
    },
    selectEmoji({ category, emoji }) {
      this.$emit('click', emoji);
      this.$refs.dropdown.hide();

      if (category !== 'custom') {
        addToFrequentlyUsed(emoji);
      }
    },
    getBoundaryElement() {
      return this.boundary || document.querySelector('.content-wrapper') || 'scrollParent';
    },
    onSearchInput() {
      this.$refs.virtualScoller.setScrollTop(0);
      this.$refs.virtualScoller.forceRender();
    },
    async onScroll(event, { offset }) {
      const categories = await getEmojiCategories();

      this.currentCategory = findLastIndex(Object.values(categories), ({ top }) => offset >= top);
    },
  },
};
</script>

<template>
  <div class="emoji-picker">
    <gl-dropdown
      ref="dropdown"
      :toggle-class="toggleClass"
      :boundary="getBoundaryElement()"
      :class="dropdownClass"
      menu-class="dropdown-extended-height"
      category="secondary"
      no-flip
      :right="right"
      lazy
      @shown="$emit('shown')"
      @hidden="$emit('hidden')"
    >
      <template #button-content>
        <slot name="button-content">
          <gl-icon class="award-control-icon-neutral gl-button-icon gl-icon" name="slight-smile" />
          <gl-icon
            class="award-control-icon-positive gl-button-icon gl-icon gl-left-3!"
            name="smiley"
          />
          <gl-icon
            class="award-control-icon-super-positive gl-button-icon gl-icon gl-left-3!"
            name="smile"
          />
        </slot>
        <span class="gl-sr-only">{{ __('Add reaction') }}</span>
      </template>
      <gl-search-box-by-type
        v-model="searchValue"
        class="gl-mx-5! gl-mb-2!"
        autofocus
        debounce="500"
        :aria-label="__('Search for an emoji')"
        @input="onSearchInput"
      />
      <div
        v-show="!searchValue"
        class="gl-display-flex gl-mx-5 gl-border-b-solid gl-border-gray-100 gl-border-b-1"
      >
        <button
          v-for="(category, index) in categoryNames"
          :key="category.name"
          :class="{
            'gl-text-body! emoji-picker-category-active': index === currentCategory,
          }"
          type="button"
          class="gl-border-0 gl-border-b-2 gl-border-b-solid gl-flex-grow-1 gl-text-gray-300 gl-pt-3 gl-pb-3 gl-bg-transparent emoji-picker-category-tab"
          :aria-label="category.name"
          @click="scrollToCategory(category.name)"
        >
          <gl-icon :name="category.icon" />
        </button>
      </div>
      <emoji-list :search-value="searchValue">
        <template #default="{ filteredCategories }">
          <virtual-list
            ref="virtualScoller"
            :size="258"
            :remain="1"
            :bench="2"
            variable
            :onscroll="onScroll"
          >
            <div
              v-for="(category, categoryKey) in filteredCategories"
              :key="categoryKey"
              :style="{ height: category.height + 'px' }"
            >
              <category :category="categoryKey" :emojis="category.emojis" @click="selectEmoji" />
            </div>
          </virtual-list>
        </template>
      </emoji-list>
    </gl-dropdown>
  </div>
</template>
