module EnrollmentAction
  class DependentAdd < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_added?(chunk)
    end

    def added_dependents
      action.all_member_ids - termination.all_member_ids
    end

    def publish
      policy_to_change = term.existing_policy
      change_publish_helper = EnrollmentAction::ActionPublishHandler.new(action.event_xml)
      change_publish_helper.set_policy_id(policy_to_change.eg_id)
      change_publish_helper.filter_affected_members(added_dependents)
      change_publish_helper.set_event_action("urn:openhbx:terms:v1:enrollment#change_member_add")
      change_publish_helper.to_xml
    end
  end
end
