import { __, s__ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATOR_NOT,
  OPERATOR_OR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  ALTERNATIVE_FILTER,
  API_PARAM,
  NORMAL_FILTER,
  SPECIAL_FILTER,
  URL_PARAM,
} from '~/issues/list/constants';

export const SERVICE_DESK_BOT_USERNAME = 'support-bot';
export const ISSUE_REFERENCE = /^#\d+$/;

export const STATUS_ALL = 'all';
export const STATUS_CLOSED = 'closed';
export const STATUS_OPEN = 'opened';

export const WORKSPACE_PROJECT = 'project';

export const filtersMap = {
  [FILTERED_SEARCH_TERM]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'search',
    },
    [URL_PARAM]: {
      [undefined]: {
        [NORMAL_FILTER]: 'search',
      },
    },
  },
  [TOKEN_TYPE_SEARCH_WITHIN]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'in',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'in',
      },
    },
  },
  [TOKEN_TYPE_ASSIGNEE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'assigneeUsernames',
      [SPECIAL_FILTER]: 'assigneeId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username[]',
        [SPECIAL_FILTER]: 'assignee_id',
        [ALTERNATIVE_FILTER]: 'assignee_username',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username][]',
      },
      [OPERATOR_OR]: {
        [NORMAL_FILTER]: 'or[assignee_username][]',
      },
    },
  },
  [TOKEN_TYPE_MILESTONE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'milestoneTitle',
      [SPECIAL_FILTER]: 'milestoneWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone_title',
        [SPECIAL_FILTER]: 'milestone_title',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[milestone_title]',
        [SPECIAL_FILTER]: 'not[milestone_title]',
      },
    },
  },
  [TOKEN_TYPE_LABEL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'labelName',
      [SPECIAL_FILTER]: 'labelName',
      [ALTERNATIVE_FILTER]: 'labelNames',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
        [SPECIAL_FILTER]: 'label_name[]',
        [ALTERNATIVE_FILTER]: 'label_name',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
      [OPERATOR_OR]: {
        [ALTERNATIVE_FILTER]: 'or[label_name][]',
      },
    },
  },
  [TOKEN_TYPE_TYPE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'types',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'type[]',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[type][]',
      },
    },
  },
  [TOKEN_TYPE_RELEASE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'releaseTag',
      [SPECIAL_FILTER]: 'releaseTagWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'release_tag',
        [SPECIAL_FILTER]: 'release_tag',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[release_tag]',
      },
    },
  },
  [TOKEN_TYPE_MY_REACTION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'myReactionEmoji',
      [SPECIAL_FILTER]: 'myReactionEmoji',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[my_reaction_emoji]',
      },
    },
  },
  [TOKEN_TYPE_CONFIDENTIAL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'confidential',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
  },
  [TOKEN_TYPE_ITERATION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'iterationId',
      [SPECIAL_FILTER]: 'iterationWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_id',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_id]',
        [SPECIAL_FILTER]: 'not[iteration_id]',
      },
    },
  },
  [TOKEN_TYPE_EPIC]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'epicId',
      [SPECIAL_FILTER]: 'epicId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'epic_id',
        [SPECIAL_FILTER]: 'epic_id',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[epic_id]',
      },
    },
  },
  [TOKEN_TYPE_WEIGHT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'weight',
      [SPECIAL_FILTER]: 'weight',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'weight',
        [SPECIAL_FILTER]: 'weight',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
  },
  [TOKEN_TYPE_HEALTH]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'healthStatusFilter',
      [SPECIAL_FILTER]: 'healthStatusFilter',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'health_status',
        [SPECIAL_FILTER]: 'health_status',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[health_status]',
      },
    },
  },
};

export const errorFetchingCounts = __('An error occurred while getting issue counts');
export const errorFetchingIssues = __('An error occurred while loading issues');
export const noSearchNoFilterTitle = __('Please select at least one filter to see results');
export const searchPlaceholder = __('Search or filter results...');
export const infoBannerTitle = s__(
  'ServiceDesk|Use Service Desk to connect with your users and offer customer support through email right inside GitLab',
);
export const infoBannerAdminNote = s__('ServiceDesk|Your users can send emails to this address:');
export const infoBannerUserNote = s__(
  'ServiceDesk|Issues created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
);
export const enableServiceDesk = s__('ServiceDesk|Enable Service Desk');
export const learnMore = __('Learn more');
export const titles = __('Titles');
export const descriptions = __('Descriptions');
export const no = __('No');
export const yes = __('Yes');
