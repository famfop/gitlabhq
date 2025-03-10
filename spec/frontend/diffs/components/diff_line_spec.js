import { shallowMount } from '@vue/test-utils';
import DiffLine from '~/diffs/components/diff_line.vue';
import InlineFindings from '~/diffs/components/inline_findings.vue';

const EXAMPLE_LINE_NUMBER = 3;
const EXAMPLE_DESCRIPTION = 'example description';
const EXAMPLE_SEVERITY = 'example severity';

const left = {
  line: {
    left: {
      codequality: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
      sast: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
    },
  },
};

const right = {
  line: {
    right: {
      codequality: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
      sast: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
    },
  },
};

const mockData = [right, left];

describe('DiffLine', () => {
  const createWrapper = (propsData) => {
    return shallowMount(DiffLine, { propsData });
  };

  it('should emit event when hideInlineFindings is called', () => {
    const wrapper = createWrapper(right);

    wrapper.findComponent(InlineFindings).vm.$emit('hideInlineFindings');
    expect(wrapper.emitted()).toEqual({
      hideInlineFindings: [[EXAMPLE_LINE_NUMBER]],
    });
  });

  mockData.forEach((element) => {
    it('should set correct props for InlineFindings', () => {
      const wrapper = createWrapper(element);
      expect(wrapper.findComponent(InlineFindings).props('codeQuality')).toEqual([
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ]);
      expect(wrapper.findComponent(InlineFindings).props('sast')).toEqual([
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ]);
    });
  });
});
