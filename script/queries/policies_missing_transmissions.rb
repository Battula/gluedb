ct_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "coverage_type")

p_repo = {}

p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])
p_map.each do |val|
    p_repo[val["member_id"]] = val["person_id"]
end

all_pol_ids = Protocols::X12::TransactionSetHeader.collection.aggregate([
  {"$match" => {
    "policy_id" => { "$ne" => nil }
  }},
  { "$group" => { "_id" => "$policy_id" }}
]).map { |val| val["_id"] }

# No cancels/terms in this batch!
pols_2015 = Policy.all.no_timeout

puts pols_2015.length

untransmitted_pols = []

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("policies_without_transmissions_#{timestamp}.csv","w") do |csv|
  csv << ["Created At", "Enrollment Group ID", "Carrier", "Employer", "Subscriber Name", "Subscriber HBX ID"]
  pols_2015.each do |pol|
    if !all_pol_ids.include?(pol.id)
      if !pol.canceled?
        unless ragus.include? pol.id
          created_at = pol.created_at
          eg_id = pol.eg_id
          carrier = pol.plan.carrier.abbrev
          employer = pol.try(:employer).try(:name)
          subscriber_name = pol.subscriber.person.full_name
          subscriber_hbx_id = pol.subscriber.m_id
          csv << [created_at,eg_id,carrier,employer,subscriber_name,subscriber_hbx_id]
        end
      end
    end
  end
end