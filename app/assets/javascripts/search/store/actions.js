import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import { labelFilterData } from '~/search/sidebar/components/label_filter/data';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY, SIDEBAR_PARAMS } from './constants';
import * as types from './mutation_types';
import {
  loadDataFromLS,
  setFrequentItemToLS,
  mergeById,
  isSidebarDirty,
  getAggregationsUrl,
  prepareSearchAggregations,
} from './utils';

export const fetchGroups = ({ commit }, search) => {
  commit(types.REQUEST_GROUPS);
  Api.groups(search, { order_by: 'similarity' })
    .then((data) => {
      commit(types.RECEIVE_GROUPS_SUCCESS, data);
    })
    .catch(() => {
      createAlert({ message: __('There was a problem fetching groups.') });
      commit(types.RECEIVE_GROUPS_ERROR);
    });
};

export const fetchProjects = ({ commit, state }, search) => {
  commit(types.REQUEST_PROJECTS);
  const groupId = state.query?.group_id;

  const handleCatch = () => {
    createAlert({ message: __('There was an error fetching projects') });
    commit(types.RECEIVE_PROJECTS_ERROR);
  };
  const handleSuccess = ({ data }) => {
    commit(types.RECEIVE_PROJECTS_SUCCESS, data);
  };

  if (groupId) {
    Api.groupProjects(groupId, search, {
      order_by: 'similarity',
      with_shared: false,
      include_subgroups: true,
    })
      .then(handleSuccess)
      .catch(handleCatch);
  } else {
    // The .catch() is due to the API method not handling a rejection properly
    Api.projects(search, { order_by: 'similarity' }).then(handleSuccess).catch(handleCatch);
  }
};

export const preloadStoredFrequentItems = ({ commit }) => {
  const storedGroups = loadDataFromLS(GROUPS_LOCAL_STORAGE_KEY);
  commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: storedGroups });

  const storedProjects = loadDataFromLS(PROJECTS_LOCAL_STORAGE_KEY);
  commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: storedProjects });
};

export const loadFrequentGroups = async ({ commit, state }) => {
  const storedData = state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
  const promises = storedData.map((d) => Api.group(d.id));
  try {
    const inflatedData = mergeById(await Promise.all(promises), storedData);
    commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: inflatedData });
  } catch {
    createAlert({ message: __('There was a problem fetching recent groups.') });
  }
};

export const loadFrequentProjects = async ({ commit, state }) => {
  const storedData = state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
  const promises = storedData.map((d) => Api.project(d.id).then((res) => res.data));
  try {
    const inflatedData = mergeById(await Promise.all(promises), storedData);
    commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: inflatedData });
  } catch {
    createAlert({ message: __('There was a problem fetching recent projects.') });
  }
};

export const setFrequentGroup = ({ state, commit }, item) => {
  const frequentItems = setFrequentItemToLS(GROUPS_LOCAL_STORAGE_KEY, state.frequentItems, item);
  commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: frequentItems });
};

export const setFrequentProject = ({ state, commit }, item) => {
  const frequentItems = setFrequentItemToLS(PROJECTS_LOCAL_STORAGE_KEY, state.frequentItems, item);
  commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: frequentItems });
};

export const setQuery = ({ state, commit }, { key, value }) => {
  commit(types.SET_QUERY, { key, value });

  if (SIDEBAR_PARAMS.includes(key)) {
    commit(types.SET_SIDEBAR_DIRTY, isSidebarDirty(state.query, state.urlQuery));
  }
};

export const applyQuery = ({ state }) => {
  visitUrl(setUrlParams({ ...state.query, page: null }, window.location.href, false, true));
};

export const resetQuery = ({ state }) => {
  visitUrl(
    setUrlParams(
      { ...state.query, page: null, state: null, confidential: null, labels: null },
      undefined,
      true,
    ),
  );
};

export const closeLabel = ({ state, commit }, { key }) => {
  const labels = state?.query?.labels.filter((labelKey) => labelKey !== key);

  setQuery({ state, commit }, { key: labelFilterData.filterParam, value: labels });
};

export const setLabelFilterSearch = ({ commit }, { value }) => {
  commit(types.SET_LABEL_SEARCH_STRING, value);
};

export const fetchSidebarCount = ({ commit, state }) => {
  const promises = Object.values(state.navigation).map((navItem) => {
    // active nav item has count already so we skip it
    if (!navItem.active) {
      return axios
        .get(navItem.count_link)
        .then(({ data: { count } }) => {
          commit(types.RECEIVE_NAVIGATION_COUNT, { key: navItem.scope, count });
        })
        .catch((e) => logError(e));
    }
    return Promise.resolve();
  });
  return Promise.all(promises);
};

export const fetchAllAggregation = ({ commit, state }) => {
  commit(types.REQUEST_AGGREGATIONS);
  return axios
    .get(getAggregationsUrl())
    .then(({ data }) => {
      commit(types.RECEIVE_AGGREGATIONS_SUCCESS, prepareSearchAggregations(state, data));
    })
    .catch((e) => {
      logError(e);
      commit(types.RECEIVE_AGGREGATIONS_ERROR);
    });
};
