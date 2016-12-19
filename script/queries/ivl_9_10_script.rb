
batch_size = 500
offset = 0
policy_count = Policy.count

csv =CSV.open("/Users/Varun/Desktop/reports/notice_12707/12707_notice_9_dec_#{DateTime.now.to_s}.csv", "w")

csv << %w(health_policy.eg_id health_policy.plan.name health_policy.pre_amt_tot health_policy.applied_aptc health_policy.policy_start health_policy.aasm_state health_policy.plan.coverage_type health_policy.plan.metal_level
          dental_policy.eg_id dental_policy.plan.name dental_policy.pre_amt_tot dental_policy.applied_aptc dental_policy.policy_start dental_policy.aasm_state dental_policy.plan.coverage_type dental_policy.plan.metal_level
        person.authority_member_id person.name_full person.mailing_address is_dependent is_responsible_party?)

def add_to_csv(csv, health_policy, dental_policy, person, is_dependent=false, is_responsible_party=false)
  csv << [health_policy.try(:eg_id), health_policy.try(:plan).try(:name), health_policy.try(:pre_amt_tot).try(:to_s), health_policy.try(:applied_aptc).try(:to_s), health_policy.try(:policy_start), health_policy.try(:aasm_state), health_policy.try(:plan).try(:coverage_type), health_policy.try(:plan).try(:metal_level),
          dental_policy.try(:eg_id), dental_policy.try(:plan).try(:name), dental_policy.try(:pre_amt_tot).try(:to_s), dental_policy.try(:applied_aptc).try(:to_s), dental_policy.try(:policy_start), dental_policy.try(:aasm_state), dental_policy.try(:plan).try(:coverage_type), dental_policy.try(:plan).try(:metal_level),
          person.authority_member_id, person.name_full, person.mailing_address.full_address,] + [is_dependent, is_responsible_party]
end

start_date = Date.new(2017,1,1)
while offset <= policy_count

  subscriber_ids = []

  Policy.offset(offset).limit(batch_size).where("enrollees.coverage_start" => {"$gte" => start_date}, :"aasm_state".in=>["submitted","resubmitted","effectuated"]).with_aptc.each do |policy|
    subscriber_ids.push(policy.subscriber.m_id) unless (policy.plan.market_type == 'shop') && policy.nil?  && policy.subscriber.nil?
  end

  subscriber_ids.uniq!
  subscribers = Person.where("members.hbx_member_id" => {"$in" => subscriber_ids})
    subscribers.each do |subscriber|
      begin
      hbx_enrollments = subscriber.policies.where("enrollees.coverage_start" => {"$gte" => start_date}, :"aasm_state".in=>["submitted","resubmitted","effectuated"], :"employer_id"=>nil)

      health_enrollments = hbx_enrollments.with_aptc.select{|p|p.plan.coverage_type == "health"}
      health_policy = health_enrollments.sort!{|a,b| b.updated_at <=> a.updated_at}.first

      dental_enrollments = hbx_enrollments.select{|p|p.plan.coverage_type == "dental"}
      dental_policy = dental_enrollments.sort!{|a,b| b.updated_at <=> a.updated_at}.first

      add_to_csv(csv, health_policy, dental_policy, subscriber, false, false)
      # if policy.responsible_party.present?
      #   add_to_csv(csv, policy, policy.responsible_party.person, false, true)
      # end
      # policy.enrollees.each do |enrollee|
      #   f = enrollee.person.families.first
      #   add_to_csv(csv, f, policy, enrollee.person, true, false) if enrollee.person != person
      # end
      rescue Exception => e
        puts "#{e.inspect} #{e.backtrace}"
      end
    end
  puts "#{offset}"
  offset = offset + batch_size
end
