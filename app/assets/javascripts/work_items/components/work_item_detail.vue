<script>
import { isEmpty } from 'lodash';
import {
  GlAlert,
  GlSkeletonLoader,
  GlLoadingIcon,
  GlIcon,
  GlBadge,
  GlButton,
  GlTooltipDirective,
  GlEmptyState,
  GlIntersectionObserver,
} from '@gitlab/ui';
import noAccessSvg from '@gitlab/svgs/dist/illustrations/analytics/no-access.svg?raw';
import { s__ } from '~/locale';
import { getParameterByName, updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import {
  sprintfWorkItem,
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_NOTIFICATIONS,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_NOTES,
} from '../constants';

import workItemUpdatedSubscription from '../graphql/work_item_updated.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '../graphql/update_work_item_task.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { findHierarchyWidgetChildren } from '../utils';

import WorkItemTree from './work_item_links/work_item_tree.vue';
import WorkItemActions from './work_item_actions.vue';
import WorkItemTodos from './work_item_todos.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemAttributesWrapper from './work_item_attributes_wrapper.vue';
import WorkItemCreatedUpdated from './work_item_created_updated.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemNotes from './work_item_notes.vue';
import WorkItemDetailModal from './work_item_detail_modal.vue';
import WorkItemAwardEmoji from './work_item_award_emoji.vue';
import WorkItemStateToggleButton from './work_item_state_toggle_button.vue';

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  isLoggedIn: isLoggedIn(),
  components: {
    WorkItemStateToggleButton,
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlSkeletonLoader,
    GlIcon,
    GlEmptyState,
    WorkItemActions,
    WorkItemTodos,
    WorkItemCreatedUpdated,
    WorkItemDescription,
    WorkItemAwardEmoji,
    WorkItemTitle,
    WorkItemAttributesWrapper,
    WorkItemTypeIcon,
    WorkItemTree,
    WorkItemNotes,
    WorkItemDetailModal,
    AbuseCategorySelector,
    GlIntersectionObserver,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'reportAbusePath'],
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    workItemParentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      error: undefined,
      updateError: undefined,
      workItem: {},
      updateInProgress: false,
      modalWorkItemId: undefined,
      modalWorkItemIid: getParameterByName('work_item_iid'),
      isReportDrawerOpen: false,
      reportedUrl: '',
      reportedUserId: 0,
      isStickyHeaderShowing: false,
    };
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data.workspace.workItems.nodes[0] ?? {};
      },
      error() {
        this.setEmptyState();
      },
      result(res) {
        // need to handle this when the res is loading: true, netWorkStatus: 1, partial: true
        if (!res.data) {
          return;
        }
        this.$emit('work-item-updated', this.workItem);
        if (isEmpty(this.workItem)) {
          this.setEmptyState();
        }
        if (!this.isModal && this.workItem.project) {
          const path = this.workItem.project?.fullPath
            ? ` · ${this.workItem.project.fullPath}`
            : '';

          document.title = `${this.workItem.title} · ${this.workItem?.workItemType?.name}${path}`;
        }
      },
      subscribeToMore: {
        document: workItemUpdatedSubscription,
        variables() {
          return {
            id: this.workItem.id,
          };
        },
        skip() {
          return !this.workItem?.id;
        },
      },
    },
  },
  computed: {
    workItemLoading() {
      return isEmpty(this.workItem) && this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItem.workItemType?.id;
    },
    workItemBreadcrumbReference() {
      return this.workItemType ? `${this.workItemType} #${this.workItem.iid}` : '';
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem?.userPermissions?.deleteWorkItem;
    },
    canSetWorkItemMetadata() {
      return this.workItem?.userPermissions?.setWorkItemMetadata;
    },
    canAssignUnassignUser() {
      return this.workItemAssignees && this.canSetWorkItemMetadata;
    },
    confidentialTooltip() {
      return sprintfWorkItem(this.$options.i18n.confidentialTooltip, this.workItemType);
    },
    fullPath() {
      return this.workItem?.project.fullPath;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    parentWorkItem() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemType() {
      return this.parentWorkItem?.workItemType?.name;
    },
    parentWorkItemIconName() {
      return this.parentWorkItem?.workItemType?.iconName;
    },
    parentWorkItemConfidentiality() {
      return this.parentWorkItem?.confidential;
    },
    parentWorkItemReference() {
      return this.parentWorkItem ? `${this.parentWorkItem.title} #${this.parentWorkItem.iid}` : '';
    },
    parentUrl() {
      // Once more types are moved to have Work Items involved
      // we need to handle this properly.
      if (this.parentWorkItemType === WORK_ITEM_TYPE_VALUE_ISSUE) {
        return `../../-/issues/${this.parentWorkItem?.iid}`;
      }
      return this.parentWorkItem?.webUrl;
    },
    workItemIconName() {
      return this.workItem?.workItemType?.iconName;
    },
    noAccessSvgPath() {
      return `data:image/svg+xml;utf8,${encodeURIComponent(noAccessSvg)}`;
    },
    hasDescriptionWidget() {
      return this.isWidgetPresent(WIDGET_TYPE_DESCRIPTION);
    },
    workItemNotificationsSubscribed() {
      return Boolean(this.isWidgetPresent(WIDGET_TYPE_NOTIFICATIONS)?.subscribed);
    },
    workItemCurrentUserTodos() {
      return this.isWidgetPresent(WIDGET_TYPE_CURRENT_USER_TODOS);
    },
    showWorkItemCurrentUserTodos() {
      return this.$options.isLoggedIn && this.workItemCurrentUserTodos;
    },
    currentUserTodos() {
      return this.workItemCurrentUserTodos?.currentUserTodos?.nodes;
    },
    workItemAssignees() {
      return this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES);
    },
    workItemAwardEmoji() {
      return this.isWidgetPresent(WIDGET_TYPE_AWARD_EMOJI);
    },
    workItemHierarchy() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY);
    },
    workItemNotes() {
      return this.isWidgetPresent(WIDGET_TYPE_NOTES);
    },
    children() {
      return this.workItem ? findHierarchyWidgetChildren(this.workItem) : [];
    },
    workItemBodyClass() {
      return {
        'gl-pt-5': !this.updateError && !this.isModal,
      };
    },
    showIntersectionObserver() {
      return !this.isModal && this.workItemsMvc2Enabled;
    },
  },
  mounted() {
    if (this.modalWorkItemIid) {
      this.openInModal({
        event: undefined,
        modalWorkItem: { iid: this.modalWorkItemIid },
      });
    }
  },
  methods: {
    isWidgetPresent(type) {
      return this.workItem?.widgets?.find((widget) => widget.type === type);
    },
    toggleConfidentiality(confidentialStatus) {
      this.updateInProgress = true;
      let updateMutation = updateWorkItemMutation;
      let inputVariables = {
        id: this.workItem.id,
        confidential: confidentialStatus,
      };

      if (this.parentWorkItem) {
        updateMutation = updateWorkItemTaskMutation;
        inputVariables = {
          id: this.parentWorkItem.id,
          taskData: {
            id: this.workItem.id,
            confidential: confidentialStatus,
          },
        };
      }

      this.$apollo
        .mutate({
          mutation: updateMutation,
          variables: {
            input: inputVariables,
          },
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors, workItem, task },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }

            this.$emit('workItemUpdated', {
              confidential: workItem?.confidential || task?.confidential,
            });
          },
        )
        .catch((error) => {
          this.updateError = error.message;
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    setEmptyState() {
      this.error = this.$options.i18n.fetchError;
      document.title = s__('404|Not found');
    },
    updateHasNotes() {
      this.$emit('has-notes');
    },
    updateUrl(modalWorkItem) {
      updateHistory({
        url: setUrlParams({ work_item_iid: modalWorkItem?.iid }),
        replace: true,
      });
    },
    openInModal({ event, modalWorkItem }) {
      if (!this.workItemsMvc2Enabled) {
        return;
      }

      if (event) {
        event.preventDefault();

        this.updateUrl(modalWorkItem);
      }

      if (this.isModal) {
        this.$emit('update-modal', event, modalWorkItem);
        return;
      }
      this.modalWorkItemId = modalWorkItem.id;
      this.modalWorkItemIid = modalWorkItem.iid;
      this.$refs.modal.show();
    },
    openReportAbuseDrawer(reply) {
      if (this.isModal) {
        this.$emit('openReportAbuse', reply);
      } else {
        this.toggleReportAbuseDrawer(true, reply);
      }
    },
    toggleReportAbuseDrawer(isOpen, reply = {}) {
      this.isReportDrawerOpen = isOpen;
      this.reportedUrl = reply.url || {};
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },
    showStickyHeader() {
      // only if scrolled under the work item's title
      if (this.$refs?.title?.$el.offsetTop < window.pageYOffset) {
        this.isStickyHeaderShowing = true;
      }
    },
  },

  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
};
</script>

<template>
  <section>
    <section v-if="updateError" class="flash-container flash-container-page sticky">
      <gl-alert class="gl-mb-3" variant="danger" @dismiss="updateError = undefined">
        {{ updateError }}
      </gl-alert>
    </section>
    <section :class="workItemBodyClass">
      <div v-if="workItemLoading" class="gl-max-w-26 gl-py-5">
        <gl-skeleton-loader :height="65" :width="240">
          <rect width="240" height="20" x="5" y="0" rx="4" />
          <rect width="100" height="20" x="5" y="45" rx="4" />
        </gl-skeleton-loader>
      </div>
      <template v-else>
        <div class="gl-display-flex gl-align-items-center" data-testid="work-item-body">
          <ul
            v-if="parentWorkItem"
            class="list-unstyled gl-display-flex gl-min-w-0 gl-mr-auto gl-mb-0 gl-z-index-0"
            data-testid="work-item-parent"
          >
            <li class="gl-ml-n4 gl-display-flex gl-align-items-center gl-min-w-0">
              <gl-button
                v-gl-tooltip.hover
                class="gl-text-truncate"
                :icon="parentWorkItemIconName"
                category="tertiary"
                :href="parentUrl"
                :title="parentWorkItemReference"
                @click="openInModal({ event: $event, modalWorkItem: parentWorkItem })"
                >{{ parentWorkItemReference }}</gl-button
              >
              <gl-icon name="chevron-right" :size="16" class="gl-flex-shrink-0" />
            </li>
            <li
              class="gl-px-4 gl-py-3 gl-line-height-0 gl-display-flex gl-align-items-center gl-overflow-hidden gl-flex-shrink-0"
            >
              <work-item-type-icon
                :work-item-icon-name="workItemIconName"
                :work-item-type="workItemType && workItemType.toUpperCase()"
              />
              {{ workItemBreadcrumbReference }}
            </li>
          </ul>
          <div
            v-else-if="!error && !workItemLoading"
            class="gl-mr-auto"
            data-testid="work-item-type"
          >
            <work-item-type-icon
              :work-item-icon-name="workItemIconName"
              :work-item-type="workItemType && workItemType.toUpperCase()"
            />
            {{ workItemBreadcrumbReference }}
          </div>
          <gl-loading-icon v-if="updateInProgress" :inline="true" class="gl-mr-3" />
          <gl-badge
            v-if="workItem.confidential"
            v-gl-tooltip.bottom
            :title="confidentialTooltip"
            variant="warning"
            icon="eye-slash"
            class="gl-mr-3 gl-cursor-help"
            >{{ __('Confidential') }}</gl-badge
          >
          <work-item-state-toggle-button
            v-if="canUpdate"
            :work-item-id="workItem.id"
            :work-item-state="workItem.state"
            :work-item-parent-id="workItemParentId"
            :work-item-type="workItemType"
            @error="updateError = $event"
          />
          <work-item-todos
            v-if="showWorkItemCurrentUserTodos"
            :work-item-id="workItem.id"
            :work-item-iid="workItemIid"
            :work-item-fullpath="workItem.project.fullPath"
            :current-user-todos="currentUserTodos"
            @error="updateError = $event"
          />
          <work-item-actions
            :work-item-id="workItem.id"
            :subscribed-to-notifications="workItemNotificationsSubscribed"
            :work-item-type="workItemType"
            :work-item-type-id="workItemTypeId"
            :can-delete="canDelete"
            :can-update="canUpdate"
            :is-confidential="workItem.confidential"
            :is-parent-confidential="parentWorkItemConfidentiality"
            :work-item-reference="workItem.reference"
            :work-item-create-note-email="workItem.createNoteEmail"
            :is-modal="isModal"
            :work-item-iid="workItemIid"
            @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
            @toggleWorkItemConfidentiality="toggleConfidentiality"
            @error="updateError = $event"
            @promotedToObjective="$emit('promotedToObjective', workItemIid)"
          />
          <gl-button
            v-if="isModal"
            category="tertiary"
            data-testid="work-item-close"
            icon="close"
            :aria-label="__('Close')"
            @click="$emit('close')"
          />
        </div>
        <div>
          <work-item-title
            v-if="workItem.title"
            ref="title"
            :work-item-id="workItem.id"
            :work-item-title="workItem.title"
            :work-item-type="workItemType"
            :work-item-parent-id="workItemParentId"
            :can-update="canUpdate"
            @error="updateError = $event"
          />
          <work-item-created-updated :work-item-iid="workItemIid" />
        </div>
        <gl-intersection-observer
          v-if="showIntersectionObserver"
          @appear="hideStickyHeader"
          @disappear="showStickyHeader"
        >
          <transition name="issuable-header-slide">
            <div
              v-if="isStickyHeaderShowing"
              class="issue-sticky-header gl-fixed gl-bg-white gl-border-b gl-z-index-3 gl-py-2"
              data-testid="work-item-sticky-header"
            >
              <div
                class="gl-align-items-center gl-mx-auto gl-px-5 gl-display-flex gl-max-w-container-xl"
              >
                <span class="gl-text-truncate gl-font-weight-bold gl-pr-3 gl-mr-auto">
                  {{ workItem.title }}
                </span>
                <gl-loading-icon v-if="updateInProgress" class="gl-mr-3" />
                <gl-badge
                  v-if="workItem.confidential"
                  v-gl-tooltip.bottom
                  :title="confidentialTooltip"
                  variant="warning"
                  icon="eye-slash"
                  class="gl-mr-3 gl-cursor-help"
                  >{{ __('Confidential') }}</gl-badge
                >
                <work-item-todos
                  v-if="showWorkItemCurrentUserTodos"
                  :work-item-id="workItem.id"
                  :work-item-iid="workItemIid"
                  :work-item-fullpath="workItem.project.fullPath"
                  :current-user-todos="currentUserTodos"
                  @error="updateError = $event"
                />
                <work-item-actions
                  :work-item-id="workItem.id"
                  :subscribed-to-notifications="workItemNotificationsSubscribed"
                  :work-item-type="workItemType"
                  :work-item-type-id="workItemTypeId"
                  :can-delete="canDelete"
                  :can-update="canUpdate"
                  :is-confidential="workItem.confidential"
                  :is-parent-confidential="parentWorkItemConfidentiality"
                  :work-item-reference="workItem.reference"
                  :work-item-create-note-email="workItem.createNoteEmail"
                  :is-modal="isModal"
                  :work-item-iid="workItemIid"
                  @deleteWorkItem="
                    $emit('deleteWorkItem', { workItemType, workItemId: workItem.id })
                  "
                  @toggleWorkItemConfidentiality="toggleConfidentiality"
                  @error="updateError = $event"
                  @promotedToObjective="$emit('promotedToObjective', workItemIid)"
                />
              </div>
            </div>
          </transition>
        </gl-intersection-observer>
        <div
          data-testid="work-item-overview"
          :class="{ 'work-item-overview': workItemsMvc2Enabled }"
        >
          <section>
            <work-item-attributes-wrapper
              :class="{ 'gl-md-display-none!': workItemsMvc2Enabled }"
              class="gl-border-b"
              :work-item="workItem"
              :work-item-parent-id="workItemParentId"
              @error="updateError = $event"
            />
            <work-item-description
              v-if="hasDescriptionWidget"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              class="gl-pt-5"
              @error="updateError = $event"
            />
            <work-item-award-emoji
              v-if="workItemAwardEmoji"
              :work-item-id="workItem.id"
              :work-item-fullpath="workItem.project.fullPath"
              :award-emoji="workItemAwardEmoji.awardEmoji"
              :work-item-iid="workItemIid"
              @error="updateError = $event"
              @emoji-updated="$emit('work-item-emoji-updated', $event)"
            />
            <work-item-tree
              v-if="workItemType === $options.WORK_ITEM_TYPE_VALUE_OBJECTIVE"
              :work-item-type="workItemType"
              :parent-work-item-type="workItem.workItemType.name"
              :work-item-id="workItem.id"
              :work-item-iid="workItemIid"
              :children="children"
              :can-update="canUpdate"
              :confidential="workItem.confidential"
              @show-modal="openInModal"
              @addChild="$emit('addChild')"
            />
            <work-item-notes
              v-if="workItemNotes"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              :work-item-type="workItemType"
              :is-modal="isModal"
              :assignees="workItemAssignees && workItemAssignees.assignees.nodes"
              :can-set-work-item-metadata="canAssignUnassignUser"
              :report-abuse-path="reportAbusePath"
              class="gl-pt-5"
              @error="updateError = $event"
              @has-notes="updateHasNotes"
              @openReportAbuse="openReportAbuseDrawer"
            />
            <gl-empty-state
              v-if="error"
              :title="$options.i18n.fetchErrorTitle"
              :description="error"
              :svg-path="noAccessSvgPath"
            />
          </section>
          <aside
            v-if="workItemsMvc2Enabled"
            data-testid="work-item-overview-right-sidebar"
            class="work-item-overview-right-sidebar gl-display-none gl-md-display-block"
            :class="{ 'is-modal': isModal }"
          >
            <work-item-attributes-wrapper
              :work-item="workItem"
              :work-item-parent-id="workItemParentId"
              @error="updateError = $event"
            />
          </aside>
        </div>
      </template>
      <work-item-detail-modal
        v-if="!isModal"
        ref="modal"
        :work-item-id="modalWorkItemId"
        :work-item-iid="modalWorkItemIid"
        :show="true"
        @close="updateUrl"
        @openReportAbuse="toggleReportAbuseDrawer(true, $event)"
      />
      <abuse-category-selector
        v-if="isReportDrawerOpen"
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedUrl"
        :show-drawer="true"
        @close-drawer="toggleReportAbuseDrawer(false)"
      />
    </section>
  </section>
</template>
