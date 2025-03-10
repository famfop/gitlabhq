import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskRoot from './components/service_desk_root.vue';

export default () => {
  const el = document.querySelector('.js-service-desk-setting-root');

  if (!el) {
    return false;
  }

  const {
    serviceDeskEmail,
    serviceDeskEmailEnabled,
    enabled,
    issueTrackerEnabled,
    endpoint,
    incomingEmail,
    outgoingName,
    projectKey,
    selectedTemplate,
    selectedFileTemplateProjectId,
    templates,
    publicProject,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      serviceDeskEmail,
      serviceDeskEmailEnabled: parseBoolean(serviceDeskEmailEnabled),
      endpoint,
      initialIncomingEmail: incomingEmail,
      initialIsEnabled: parseBoolean(enabled),
      isIssueTrackerEnabled: parseBoolean(issueTrackerEnabled),
      outgoingName,
      projectKey,
      selectedTemplate,
      selectedFileTemplateProjectId: parseInt(selectedFileTemplateProjectId, 10) || null,
      templates: JSON.parse(templates),
      publicProject: parseBoolean(publicProject),
    },
    render: (createElement) => createElement(ServiceDeskRoot),
  });
};
