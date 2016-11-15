
batch_size = 500
offset = 0
family_count = Family.count

csv =CSV.open("/Users/Varun/Desktop/reports/nov_14/11455_export_glue_plan_family_no_dependents.csv", "w")

csv << %w(family.e_case_id policy.eg_id policy.plan.name policy.renewal_plan.name hbx_enrollment.policy.policy_start policy.aasm_state policy.plan.coverage_type policy.plan.metal_level
        person.authority_member_id person.name_full person.mailing_address person.authority_member.is_incarcerated person.authority_member.citizen_status
        person.authority_member.is_state_resident is_dependent is_responsible_party?)

def add_to_csv(csv, family, policy, person, is_dependent=false, is_responsible_party=false)
  csv << [family.try(:e_case_id), policy.try(:eg_id), policy.plan.name, policy.plan.try(:renewal_plan).try(:name), policy.policy_start, policy.aasm_state, policy.plan.coverage_type, policy.plan.metal_level, person.authority_member_id, person.name_full, person.mailing_address.full_address,
          person.authority_member.try(:is_incarcerated), person.authority_member.try(:citizen_status),
          person.authority_member.try(:is_state_resident)] + [is_dependent, is_responsible_party]
end

while offset < family_count
    Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |hbx_enrollment|
    # Policy.offset(offset).limit(batch_size).each do |policy|
    begin
      policy = hbx_enrollment.policy
      family = hbx_enrollment.family

      next if policy.nil?
      next if policy.policy_start < Date.new(2016, 01, 01)
      next if !policy.is_active?
      next if (policy.applied_aptc != 0) || (policy.plan.market_type == 'shop')
      person = policy.subscriber.person

      add_to_csv(csv, family, policy, person, false, false)

      if policy.responsible_party.present?
        add_to_csv(csv, family, policy, policy.responsible_party.person, false, true)
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