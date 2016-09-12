batch_size = 500
offset = 0
policy_count = Policy.count

csv =CSV.open("10655_export_glue_rowwise.csv", "w")

csv << %w(policy.eg_id hbx_enrollment.policy.policy_start policy.aasm_state policy.plan.coverage_type policy.plan.metal_level
        person.authority_member_id person.authority_member.is_incarcerated person.authority_member.citizen_status
        person.authority_member.is_state_resident person.authority_member.is_dependent is_responsible_party? authority_member_id
        authority_member.is_incarcerated authority_member.citizen_status
        authority_member.is_state_resident)

def add_to_csv(csv, policy, person, is_dependent=false, is_responsible_party=false)
  csv << [policy.eg_id, policy.policy_start, policy.aasm_state, policy.plan.coverage_type, policy.plan.metal_level, person.authority_member_id,
          person.authority_member.is_incarcerated, person.authority_member.citizen_status,
          person.authority_member.is_state_resident] + [is_dependent, is_responsible_party]
end

def csr_variant?(plan)
  csr = plan.hios_plan_id.split('-')
  if csr.length == 1
    false
  elsif csr.last.eql?('01')
    false
  else
    true
  end
end

while offset < policy_count
  #Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |hbx_enrollment|
  Policy.offset(offset).limit(batch_size).each do |policy|
    begin
      next if policy.nil?
      next if policy.policy_start < Date.new(2016, 01, 01)
      next if !policy.is_active?
      next if (policy.plan.coverage_type != 'health') || (policy.plan.metal_level == "catastrophic") ||
          (policy.applied_aptc != 0) || (policy.plan.market_type == 'shop')
      next if csr_variant?(policy.plan)

      person = policy.subscriber.person

      #add_to_csv(csv, policy, person, false, false)

      row = [policy.eg_id, policy.policy_start, policy.aasm_state, policy.plan.coverage_type, policy.plan.metal_level, person.authority_member_id,
             person.authority_member.is_incarcerated, person.authority_member.citizen_status,
             person.authority_member.is_state_resident, false, policy.responsible_party.present?]

      if policy.responsible_party.present?
        #add_to_csv(csv, policy, policy.responsible_party.person, false, true)
        row = row + [policy.responsible_party.person.authority_member_id,
                     policy.responsible_party.person.authority_member.is_incarcerated, policy.responsible_party.person.authority_member.citizen_status,
                     policy.responsible_party.person.authority_member.is_state_resident]
      end

      policy.enrollees.each do |enrollee|
        next if enrollee.person == person
        row = row + [enrollee.person.authority_member_id,
                     enrollee.person.authority_member.is_incarcerated, enrollee.person.authority_member.citizen_status,
                     enrollee.person.authority_member.is_state_resident]
      end

      csv << row
    rescue => e
      puts "Error policy eg_id #{policy.eg_id} " + e.message + " " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end