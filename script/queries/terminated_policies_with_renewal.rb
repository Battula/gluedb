# Finds terminated people who have a 2016 renewal. Could be modified for later. 
require 'csv'

## Requirements: 
### Exclude people with no active 2016 policies
### Exclude people with no inactive 2015 policies. 


subscribers = []

start_date = Date.new(2015,1,1)

policies_to_review = Policy.where(:enrollees => {"$elemMatch" => {:rel_code => "self",
											 					  :coverage_start => {"$gte" => start_date}}})

## To optimize this, write a query that will extract the subscriber's ID from every single policy object. 

time = Time.now
puts "#{time} - #{policies_to_review.count} subscribers to potentially pull."


policies_to_review.each do |policy|
	next if policy.enrollees.first.coverage_start.year == 2016
	policy.enrollees.each do |enrollee|
		if enrollee.rel_code == "self"
			subscribers.push(enrollee.person)
		end
	end
end

time = Time.now
puts "#{time} - #{subscribers.count} subscribers."

subscribers.uniq!

puts "#{time} - #{subscribers.count} unique subscribers"

count = 0

CSV.open("2015_terminated_policies_with_renewal.csv", "w") do |csv|
	csv << ["Policy ID", "State", "Subscriber Name", "Coverage Type", "Effective Date", "Termination Date"]
	subscribers.each do |subscriber|
		count += 1
		time = Time.now
		puts "#{time} - #{count}" if count % 1000 == 0
		policies = subscriber.policies.to_a
		policies_2014 = []
		policies_2015 = []
		policies_2016 = []
		policies.each do |policy|
			if policy.enrollees.first.coverage_start.year == 2015 and policy.aasm_state != "canceled"
				policies_2015.push(policy)
			elsif policy.enrollees.first.coverage_start.year == 2016
				policies_2016.push(policy)
			end
		end
		next if policies_2015.all?{|policy| policy.enrollees.first.coverage_end == nil}
		policies_2015_health = []
		policies_2015_dental = []
		policies_2015.each do |policy|
			if policy.coverage_type == "health"
				policies_2015_health.push(policy)
			elsif policy.coverage_type == "dental"
				policies_2015_dental.push(policy)
			end
		end
		next if policies.all?{|policy| policy.enrollees.first.coverage_start.year <= 2015 }
		next if policies.count == 1
		next if policies_2016.all?{|policy| policy.subscriber.coverage_end != nil}
		policies_2015_health.sort_by!{|policy| policy.enrollees.first.coverage_start}
		policies_2015_dental.sort_by!{|policy| policy.enrollees.first.coverage_start}
		policies_to_write = []
		if policies_2015_health.count != 0
			if policies_2015_health.last.aasm_state == "canceled" or policies_2015_health.last.aasm_state == "terminated"
				policies.each do |policy|
					next if policy.enrollees.first.coverage_start.year == 2014
					next if policy.enrollees.first.coverage_start.year == 0015
					next if policy.aasm_state == "canceled"
					next if policy.coverage_type == "dental"
					policies_to_write.push(policy)
				end
			end
		end
		if policies_2015_dental.count != 0
			if policies_2015_dental.last.aasm_state == "canceled" or policies_2015_dental.last.aasm_state == "terminated"
				policies.each do |policy|
					next if policy.enrollees.first.coverage_start.year == 2014
					next if policy.enrollees.first.coverage_start.year == 0015
					next if policy.aasm_state == "canceled"
					next if policy.coverage_type == "health"
					policies_to_write.push(policy)
				end
			end
		end
		if policies_to_write.count > 1
			policies_to_write.each do |policy|
				id = policy._id
				aasm_state = policy.aasm_state
				effective_date = policy.enrollees.first.coverage_start
				end_date = policy.enrollees.first.try(:coverage_end)
				csv << [id, aasm_state, subscriber.name_full, policy.coverage_type, effective_date, end_date]	
			end
		end
	end # Ends subscribers.each
end # Ends CSV.open

