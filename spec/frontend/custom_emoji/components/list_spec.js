import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import List from '~/custom_emoji/components/list.vue';
import { CUSTOM_EMOJI } from '../mock_data';

jest.mock('~/lib/utils/datetime/date_format_utility', () => ({
  formatDate: (date) => date,
}));

Vue.config.ignoredElements = ['gl-emoji'];

let wrapper;

function createComponent(propsData = {}) {
  wrapper = mountExtended(List, {
    propsData: {
      customEmojis: CUSTOM_EMOJI,
      pageInfo: {},
      count: CUSTOM_EMOJI.length,
      ...propsData,
    },
  });
}

describe('Custom emoji settings list component', () => {
  it('renders table of custom emoji', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('pagination', () => {
    it.each`
      emits                        | button          | pageInfo
      ${{ before: 'startCursor' }} | ${'prevButton'} | ${{ hasPreviousPage: true, startCursor: 'startCursor' }}
      ${{ after: 'endCursor' }}    | ${'nextButton'} | ${{ hasNextPage: true, endCursor: 'endCursor' }}
    `('emits $emits when $button is clicked', async ({ emits, button, pageInfo }) => {
      createComponent({ pageInfo });

      await wrapper.findByTestId(button).vm.$emit('click');

      expect(wrapper.emitted('input')[0]).toEqual([emits]);
    });
  });
});
