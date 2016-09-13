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
untransmitted = File.new("policies_without_transmissions_#{timestamp}.txt", "w")

pols_2015.each do |pol|
  if !all_pol_ids.include?(pol.id)
    if !pol.canceled?
      unless ragus.include? pol.id
        untransmitted.puts("#{pol.created_at} - #{pol.eg_id} - #{pol.plan.carrier.abbrev} - #{pol.try(:employer).try(:name)} - #{pol.subscriber.person.full_name}")
        untransmitted_pols << pol.id
      end
    end
  end
end


untrans_length = untransmitted_pols.length
untransmitted.puts("#{untrans_length}")
