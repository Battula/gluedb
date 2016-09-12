# Finds all policies with subscriber who has a birth date in 2015. 
require 'csv'

dob_start = Date.new(2015,1,1)

subscribers_for_eval = []

CSV.open("2015_birth_date_subscribers.csv", "w") do |csv|
	csv << ["Policy ID", "Subscriber Name", "DOB", "Responsible Party", "Plan Name", "Effective Date"]
	Policy.all.each do |policy|
		next if policy.enrollees.first.coverage_start == 2014
		begin
		if policy.subscriber.person.members.first.dob.year >= 2015
			policy_id = policy._id
			subscribery = policy.subscriber.person
			subscriber_name = subscribery.name_full
			subscriber_dob = subscribery.members.first.dob
			plan_name = policy.plan.name
			effective_date = policy.subscriber.coverage_start
			responsible_party = policy.try(:responsible_party)
			csv << [policy_id, subscriber_name, subscriber_dob, responsible_party, plan_name, effective_date]
		end
		rescue Exception=>e
			puts "#{policy._id} - #{e.message}"
		end
	end
end
