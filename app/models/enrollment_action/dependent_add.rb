module EnrollmentAction
  class DependentAdd < Base
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_added?(chunk)
    end

    def self.dependents_added?(chunk)
    end

    def self.same_plan?(chunk)
    end

    def persist
      true
    end

    def added_dependents
      []
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
