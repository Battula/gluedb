carrier_ids = Carrier.where({
 :abbrev => {"$ne" => "GHMSI"}
}).map(&:id)

puts carrier_ids

plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids}).map(&:id)

eligible_m_pols = pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2015,12,31)}
  }}, :employer_id => nil, :plan_id => {"$in" => plan_ids}}).no_timeout

eligible_pols = pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2015,12,31)}
  }}, :employer_id => nil, :plan_id => {"$in" => plan_ids}}).no_timeout

m_ids = []

eligible_pols.each do |pol|
  if !pol.canceled?
    pol.enrollees.each do |en|
      m_ids << en.m_id
    end
  end
end

m_cache = Caches::MemberCache.new(m_ids)

Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)

active_end = Date.new(2016,1,31)

eligible_pols.each do |pol|
  if !pol.canceled?
    if !(pol.subscriber.coverage_start > active_end)
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
