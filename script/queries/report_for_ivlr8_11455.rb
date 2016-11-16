
batch_size = 500
offset = 0
policy_count = Policy.count

csv =CSV.open("/Users/Varun/Desktop/reports/nov_16/11455_export_glue_plan_family_no_dependents.csv", "w")

csv << %w( policy.eg_id policy.plan.name policy.pre_amt_tot policy.policy_start policy.aasm_state policy.plan.coverage_type policy.plan.metal_level
        person.authority_member_id person.name_full person.mailing_address person.authority_member.is_incarcerated person.authority_member.citizen_status
        person.authority_member.is_state_resident is_dependent is_responsible_party?)

def add_to_csv(csv, policy, person, is_dependent=false, is_responsible_party=false)
  csv << [ policy.try(:eg_id), policy.plan.name, policy.pre_amt_tot.to_s, policy.policy_start, policy.aasm_state, policy.plan.coverage_type, policy.plan.metal_level, person.authority_member_id, person.name_full, person.mailing_address.full_address,
          person.authority_member.try(:is_incarcerated), person.authority_member.try(:citizen_status),
          person.authority_member.try(:is_state_resident)] + [is_dependent, is_responsible_party]
end

while offset < policy_count
    # Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |hbx_enrollment|
    # Policy.offset(offset).limit(batch_size).each do |policy|
    start_date = Date.new(2017,1,1)
    Policy.offset(offset).limit(batch_size).where("enrollees.coverage_start" => {"$gte" => start_date}).each do |policy|
    begin
      next if policy.nil?
      next if policy.subscriber.blank?
      next if policy.policy_start < Date.new(2017, 01, 01)
      next if (policy.canceled?) || (policy.terminated?)
      next if (policy.applied_aptc != 0) || (policy.plan.market_type == 'shop') || (policy.plan.market_type == nil)

      person = policy.subscriber.person

      add_to_csv(csv, policy, person, false, false)

      if policy.responsible_party.present?
        add_to_csv(csv, policy, policy.responsible_party.person, false, true)
      end
      # policy.enrollees.each do |enrollee|
      #   f = enrollee.person.families.first
      #   add_to_csv(csv, f, policy, enrollee.person, true, false) if enrollee.person != person
      # end
    rescue => e
      puts "Error policy eg_id #{policy.eg_id}" + e.message + " " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end