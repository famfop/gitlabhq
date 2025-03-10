<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '../constants';
import SearchableDropdown from './searchable_dropdown.vue';

export default {
  name: 'ProjectFilter',
  components: {
    SearchableDropdown,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  computed: {
    ...mapState(['query', 'projects', 'fetchingProjects']),
    ...mapGetters(['frequentProjects', 'currentScope']),
    selectedProject() {
      return this.initialData ? this.initialData : ANY_OPTION;
    },
  },
  created() {
    // This tracks projects searched via the top nav search bar
    if (this.query.nav_source === 'navbar' && this.initialData?.id) {
      this.setFrequentProject(this.initialData);
    }
  },
  methods: {
    ...mapActions(['fetchProjects', 'setFrequentProject', 'loadFrequentProjects']),
    handleProjectChange(project) {
      // If project.id is null we are clearing the filter and don't need to store that in LS.
      if (project.id) {
        this.setFrequentProject(project);
      }

      // This determines if we need to update the group filter or not
      const queryParams = {
        ...(project.namespace?.id && { [GROUP_DATA.queryParam]: project.namespace.id }),
        [PROJECT_DATA.queryParam]: project.id,
        nav_source: null,
        scope: this.currentScope,
      };

      visitUrl(setUrlParams(queryParams));
    },
  },
  PROJECT_DATA,
};
</script>

<template>
  <searchable-dropdown
    data-testid="project-filter"
    :header-text="$options.PROJECT_DATA.headerText"
    :name="$options.PROJECT_DATA.name"
    :full-name="$options.PROJECT_DATA.fullName"
    :loading="fetchingProjects"
    :selected-item="selectedProject"
    :items="projects"
    :frequent-items="frequentProjects"
    @first-open="loadFrequentProjects"
    @search="fetchProjects"
    @change="handleProjectChange"
  />
</template>
