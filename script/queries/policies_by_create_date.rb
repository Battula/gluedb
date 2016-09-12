# Returns all policies created on a certain date.
require 'csv'
require 'mongoid'

start_date = Time.mktime(2016,3,16,0,0,0)

policies = Policy.where(:created_at => {"$gte" => start_date}, :employer_id => {"$ne" => nil})

db = Mongoid::Sessions.default
person_collection = db[:people]

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

CSV.open("policies_created_on_or_after_#{start_date}.csv", "w") do |csv|
	csv << ["Enrollment Group ID","Employer Name", "Employer FEIN","Subscriber Name","Subscriber HBX ID", "Plan", "Plan HIOS", "Start Date"]
	policies.each do |policy|
		eg_id = policy.eg_id
		employer = Caches::MongoidCache.lookup(Employer,policy.employer_id) {employer}
		employer_name = employer.name
		employer_fein = employer.fein
		subscriber_hbx_id = policy.subscriber.m_id
		subscriber_person = person_collection.find("members.hbx_member_id" => subscriber_hbx_id).first
		subscriber_name = subscriber_person["name_full"]
		plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
		plan_name = plan.name
		plan_hios = plan.hios_plan_id
		coverage_start = policy.subscriber.coverage_start
		csv << [eg_id, employer_name,employer_fein,subscriber_name,subscriber_hbx_id,plan_name,plan_hios,coverage_start]
	end
end

end # Ends the Mongoid Cache