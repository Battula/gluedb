# Returns all shop policies that have no premium payments, so long as they are not canceled and are not a 2014 policy.
require 'csv'

shop_policies = Policy.where(:employer_id => {"$ne" => nil})

def find_subscriber(policy)
	subscriber = policy.subscriber
	if subscriber == nil
		policy.enrollees.each do |enr|
			if enr.rel_code == "self"
				subscriber = enr
			end
		end
	end
	return subscriber
end

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("shop_policies_missing_premium_payments_#{timestamp}.csv","w") do |csv|
	csv << ["Enrollment Group ID", "Coverage Start", "Subscriber Name", "Subscriber HBX ID", "Plan", "Employer Name", "Employer FEIN"]
		shop_policies.each do |shop_policy|
			begin
			subscriber = find_subscriber(shop_policy)
			next if subscriber == nil
			next if shop_policy.canceled?
			next if subscriber.coverage_start.year == 2014
			if shop_policy.premium_payments.count == 0
				eg_id = shop_policy.eg_id
				coverage_start = subscriber.coverage_start
				subscriber_name = subscriber.person.name_full
				subscriber_hbx_id = subscriber.m_id
				plan = shop_policy.plan.name
				employer = shop_policy.employer
				employer_name = employer.name
				employer_fein = employer.fein
				csv << [eg_id, coverage_start, subscriber_name, subscriber_hbx_id, plan, employer_name, employer_fein]
			end
			rescue Exception=>e
				puts e.message
				puts "#{shop_policy._id}"
				next
			end
		end
end