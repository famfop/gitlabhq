import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';

Vue.use(Vuex);

describe('StatusFilter', () => {
  let wrapper;

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = shallowMount(StatusFilter, {
      store,
    });
  };

  const findRadioFilter = () => wrapper.findComponent(RadioFilter);

  describe('old sidebar', () => {
    beforeEach(() => {
      createComponent({ useSidebarNavigation: false });
    });

    it('renders the component', () => {
      expect(findRadioFilter().exists()).toBe(true);
    });
  });

  describe('new sidebar', () => {
    beforeEach(() => {
      createComponent({ useSidebarNavigation: true });
    });

    it('renders the component', () => {
      expect(findRadioFilter().exists()).toBe(true);
    });
  });
});
