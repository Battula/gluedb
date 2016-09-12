carrier_ids = Carrier.where({
 :abbrev => {"$eq" => "GHMSI"}
}).map(&:id)

puts carrier_ids

active_start = Date.new(2015,7,31)
active_end = Date.new(2016,7,31)

plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids}).map(&:id)

employer_ids = PlanYear.where(:start_date => {"$gt" => active_start, "$lt" => active_end}).map(&:employer_id)

congress_feins = []

cong_employer_ids = Employer.where(:fein => {"$in" => congress_feins}).map(&:id)

eligible_m_pols = pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => active_start}
  }}, :employer_id => {"$in" => employer_ids}, :plan_id => {"$in" => plan_ids}}).no_timeout

eligible_pols = pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => active_start}
  }}, :employer_id => {"$in" => employer_ids}, :plan_id => {"$in" => plan_ids}}).no_timeout

m_ids = []

eligible_pols.each do |pol|
  if !pol.canceled?
    pol.enrollees.each do |en|
      m_ids << en.m_id
    end
  end
end

def current_plan_year(employer)
  today = Time.now.to_date
  employer.plan_years.each do |plan_year|
    py_start = plan_year.start_date
    py_end = plan_year.end_date
    date_range = (py_start..py_end)
    if date_range.include?(today)
      return plan_year
    end
  end
end

def in_current_plan_year?(policy,employer)
  plan_year = current_plan_year(employer)
  policy_start_date = policy.subscriber.coverage_start
  py_start = plan_year.start_date
  py_end = plan_year.end_date
  date_range = (py_start..py_end)
  if date_range.include?(policy_start_date)
    return true
  else
    return false
  end
end

m_cache = Caches::MemberCache.new(m_ids)

Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)
Caches::MongoidCache.allocate(Employer)

eligible_pols.each do |pol|
  if !pol.canceled?
    if !(pol.subscriber.coverage_start > active_end)
      employer = Caches::MongoidCache.lookup(Employer, pol.employer_id) {pol.employer}
      if cong_employer_ids.include?(pol.employer_id) and pol.subscriber.coverage_start.year != 2016
        next
      elsif in_current_plan_year?(pol,employer) == false
        next
      end
      subscriber_id = pol.subscriber.m_id
      subscriber_member = m_cache.lookup(subscriber_id)
      auth_subscriber_id = subscriber_member.person.authority_member_id
      if auth_subscriber_id == subscriber_id
        enrollee_list = pol.enrollees.reject { |en| en.canceled? }
        all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
        out_f = File.open(File.join("audits", "#{pol._id}_audit.xml"), 'w')
        ser = CanonicalVocabulary::MaintenanceSerializer.new(
          pol,
          "audit",
          "notification_only",
          all_ids,
          all_ids,
          { :term_boundry => active_end,
            :member_repo => m_cache }
        )
        out_f.write(ser.serialize)
        out_f.close
      end
    end
  end
end
