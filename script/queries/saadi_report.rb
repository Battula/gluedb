require 'csv'
# dental_plan_ids = Plan.where({"coverage_type" => "dental"}).map(&:id).map { |tid| Moped::BSON::ObjectId.from_string(tid) }

policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/}}
)

def bad_eg_id(eg_id)
 (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

plan_hash = Plan.all.inject({}) do |acc, p|
  acc[p.id] = p
  acc
end

carrier_hash = Carrier.all.inject({}) do |acc, c|
  acc[c.id] = c
  acc
end

employer_hash = Employer.all.inject({}) do |acc, e|
  acc[e.id] = e.name
  acc
end

def last_payment(policy)
  count = policy.premium_payments.count
  if count == 0
    return "No Premium Payments"
  elsif count == 1
    return policy.premium_payments.last
  elsif count > 1
    last_payment = policy.premium_payments.to_a.sort_by!{|premium_payment| premium_payment.paid_at}.last
    return last_payment
  end
end

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("saadi_report_#{timestamp}.csv", 'w') do |csv|
  csv << ["Enrollment Group ID", "Status", "Authority", "Policy ID", "Number of Transactions", "Sponsor", "Employer FEIN", "Premium Total", "Contribution/APTC", "Total Responsible", "Coverage Type", "Plan HIOS ID", "Plan Name", "Carrier Name", "HBX Id", "Subscriber", "First", "Middle", "Last", "DOB", "SSN", "Gender", "Start", "End", "Updated At", "Last Premium Payment Date", "Last Premium Payment Amount"]
  policies.each_slice(25) do |pols|
    used_policies = pols.reject { |pl| bad_eg_id(pl) }
    member_ids = pols.map(&:enrollees).flatten.map(&:m_id)
    people = Person.where({
      "members.hbx_member_id" => {"$in" => member_ids }
    })
    members_map = people.inject({}) do |acc, p|
      p.members.each do |m|
        acc[m.hbx_member_id] = [m, p]
      end
      acc
    end
    used_policies.each do |pol|
      plan = plan_hash[pol.plan_id]
      carrier = carrier_hash[plan.carrier_id]
      sponsor = pol.employer.blank? ? "Individual" : employer_hash[pol.employer_id]
      fein = pol.try(:employer).try(:fein)
      last_prem_payment = last_payment(pol)
      if last_prem_payment != "No Premium Payments"
        paid_at = last_prem_payment.paid_at
        paid_amount = (last_prem_payment.pmt_amt.to_d)/100.to_d
      end
      csv_transactions = pol.csv_transactions.count
      other_transactions = pol.transaction_set_enrollments.count
      all_transactions = csv_transactions + other_transactions
      pol.enrollees.each do |en|
        member = members_map[en.m_id].first
        per = members_map[en.m_id].last
        pol.is_shop? ? contribution = pol.employer_contribution : contribution = pol.applied_aptc
        pol.is_shop? ? sponsor = pol.employer.name : sponsor = "IVL"
        csv << [pol.eg_id, pol.aasm_state, member.authority?, pol._id, sponsor, fein, all_transactions, pol.total_premium_amount,contribution,pol.total_responsible_amount,plan.coverage_type ,plan.hios_plan_id, plan.name, carrier.name, en.m_id, en.subscriber?, per.name_first, per.name_middle, per.name_last, member.dob.strftime("%Y%m%d"), member.ssn, member.gender, en.coverage_start.strftime("%m-%d-%Y"), (en.coverage_end.strftime("%m-%d-%Y") unless en.coverage_end.blank?),pol.updated_at.strftime("%m-%d-%Y %I:%M:%S %p %Z"), paid_at, paid_amount.to_s]
      end
    end
  end
end