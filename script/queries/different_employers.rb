# This script finds people with policies from different employers. 

require 'csv'

subscribers = []

policies_to_review = Policy.where(:employer_id => {"$ne" => nil})

time = Time.now
puts "#{time} - #{policies_to_review.count} subscribers to potentially pull."

policies_to_review.each do |policy|
	policy.enrollees.each do |enrollee|
		if enrollee.rel_code == "self"
			subscribers.push(enrollee.person)
		end
	end
end

time = Time.now
puts "#{time} - #{subscribers.count} subscribers."

subscribers.uniq!

time = Time.now
puts "#{time} - #{subscribers.count} unique subscribers"

CSV.open("different_employer_policies.csv", "w") do |csv|
	csv << ["Policy ID", "Employer", "Subscriber", "HBX ID", "Plan Selection", "Start Date", "End Date"]
	subscribers.each do |subscriber|
		employer_ids = []
		policies = subscriber.policies
		policies.each do |policy|
			next if policy.employer_id == nil
			employer_ids.push(policy.employer_id)
		end
		employer_ids.uniq! 
		if employer_ids.count > 1
			policies.each do |policy|
				next if policy.employer_id == nil
				next if policy.aasm_state == "canceled"
				id = policy._id
				employer_name = policy.employer.name
				hbx_id = policy.subscriber.m_id
				subscriber_name = policy.subscriber.person.name_full
				plan_name = policy.plan.name
				start_date = policy.subscriber.coverage_start
				end_date = policy.subscriber.coverage_end
				csv << [id, employer_name, subscriber_name, hbx_id, plan_name, start_date, end_date]
			end
		end
	end
end