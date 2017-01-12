module Handlers
  class EnrichHandler < Base
    include ::Handlers::EnrollmentEventXmlHelper

    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

    def call(context)
      event_list = merge_or_split(context, context.event_list)
      if !context.errors.has_errors?
        event_list.map do |element|
          super(duplicate_context(context, element))
        end
      else
        [context]
      end
    end

    def duplicate_context(context, event_xml)
      new_context = context.clone
      new_context.event_message = event_xml
      new_context
    end

    def merge_or_split(context, event_list)
      last_event = event_list.last.event_xml
      enrollment_event_cv = enrollment_event_cv_for(last_event)
      policy_cv = extract_policy(enrollment_event_cv)
      if event_list.length > 1
        context.errors.add(:process, "These events represent a compound event flow, and we don't handle that yet.")
        return []
      end
      if already_exists?(policy_cv)
        context.errors.add(:process, "The enrollment to create already exists")
        return []
      end
      if determine_market(enrollment_event_cv) == "shop"
        validator = ShopEnrichmentValidator.new(context.errors, enrollment_event_cv, policy_cv, last_event)
        return [] unless validator.valid?
        event_list.map do |ev|
          rewrite_shop_ids(context, ev, validator.should_be_renewal?, validator.terminations)
        end
      else
        validator = IvlEnrichmentValidator.new(context.errors, enrollment_event_cv, policy_cv, last_event)
        return [] unless validator.valid?
        disposition = BusinessProcesses::IvlPolicyDisposition.new(enrollment_event_cv, policy_cv)
        context.terminations = disposition.terminations
        context.cancellations = disposition.cancels
        new_event = event_list.last
        new_event_xml = transform_action_to(last_event, disposition.policy_action)
        new_event.event_xml = new_event_xml
        [new_event]
      end
    end

    def rewrite_shop_ids(context, event_item, is_renewal, terminations)
      event_xml = event_item.event_xml
      enrollment_event_cv = enrollment_event_cv_for(event_xml)
      policy_cv = extract_policy(enrollment_event_cv)
      new_action = is_renewal ? "urn:openhbx:terms:v1:enrollment#change_product" : "urn:openhbx:terms:v1:enrollment#initial"
      context.terminations = context.terminations + terminations
      event_item.event_xml = transform_action_to(event_xml, new_action)
      event_item
    end

    def already_exists?(policy_cv)
      enrollment_group_id = extract_enrollment_group_id(policy_cv)
      Policy.where(:eg_id => enrollment_group_id).any?
    end

    def extract_policy_details(policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_id = extract_member_id(subscriber_enrollee)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      coverage_type = plan.coverage_type
      subscriber_person = Person.find_by_member_id(subscriber_id)
      [plan, subscriber_person, subscriber_id, subscriber_start]
    end

    def is_ivl_active_renewal?(enrollment_event_cv)
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#active_renew"
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_passive_renewal?(enrollment_event_cv)
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#auto_renew",
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_renewal?(enrollment_event_cv)
      is_ivl_passive_renewal?(enrollment_event_cv) || is_ivl_active_renewal?(enrollment_event_cv)
    end

    def ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.is_shop?
      return false unless (pol.plan.year == plan.year - 1)
      return false unless (pol.plan.carrier_id == plan.carrier_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false if pol.canceled?
      return false if pol.terminated?
      true
    end

    def transform_action_to(event_xml, action_uri)
      event_doc = Nokogiri::XML(event_xml)
      found_action = false
      event_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:type", XML_NS).each do |node|
        found_action = true
        node.content = action_uri
      end
      raise "Could not find enrollment action to correct it" unless found_action
      event_doc.to_xml(:indent => 2)
    end
  end
end
