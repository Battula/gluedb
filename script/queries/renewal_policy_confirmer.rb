# very broad query that checks to see if an active 2015 policy has a 2016 renewal (whether active or passive).
require 'csv'

start_date = Date.new(2014,12,31)

end_date = Date.new(2016,1,1)

policies_2015_analysis = PolicyStatus::Active.between(Date.new(2014,12,31), Date.new(2015,12,31)).results.where(:employer_id => nil)

subscribers = []

policies_2015_analysis.each do |policy|
	next if policy.employer_id != nil
	policy.enrollees.each do |enrollee|
		if enrollee.rel_code == "self"
			subscribers.push(enrollee.person)
		end
	end
end

subscribers.uniq!

puts "#{subscribers.count} subscribers to review."

health_count = 0

start_date_2016 = Date.new(2016,1,1)

CSV.open("remaining_renewal_policies_health.csv", "w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Authority ID", "Subscriber Name", "Created On", "Updated On", "Age on 1-1-16", "2016 Policies"]
	subscribers.each do |subscriber|
		health_count += 1
		if health_count % 1000 == 0
			puts "#{health_count} health subscribers reviewed."
		end
		sub_policies_2015_health = []
		sub_policies_2016_health = []
		subscriber.policies.each do |policy|
			begin
			next if policy.enrollees.first.coverage_start.year == 2014
			next if policy.employer_id != nil
			subby = policy.subscriber
			if subby == nil
				policy.enrollees.each do |enrollee|
					if enrollee.rel_code == "self"
						subby = enrollee
					end
				end
			end
			next if (subby.m_id != subscriber.authority_member_id) and (subby.coverage_start.year == 2015)
			if policy.coverage_type == "health" and subby.coverage_start.year == 2015
				sub_policies_2015_health.push(policy)
			elsif subby.coverage_start.year == 2015 and policy.aasm_state == "canceled"
				next
			elsif policy.coverage_type == "health" and subby.coverage_start.year == 2016
				sub_policies_2016_health.push(policy)
			end
			rescue
				puts policy._id
				next
			end
		end
		next if sub_policies_2015_health.count == 0
		sub_policies_2015_health.sort_by! {|policy| policy.subscriber.coverage_start}
		if sub_policies_2015_health.last.subscriber.coverage_end != nil
			next
		else
			policy_id_2015 = sub_policies_2015_health.last._id
			plan_name_2015 = sub_policies_2015_health.last.plan.name
			subscriber_2015_hbx_id = sub_policies_2015_health.last.subscriber.m_id
			subscriber_authority_id = subscriber.authority_member_id
			subscriber_2015_name = sub_policies_2015_health.last.subscriber.person.name_full
			if sub_policies_2015_health.last.plan.metal_level.downcase == "catastrophic"
				age = (start_date_2016 - subscriber.members.first.dob)/365.25
			else
				age = "n/a"
			end
			created_on = sub_policies_2015_health.last.created_at
			updated_on = sub_policies_2015_health.last.updated_at
			policy_count_2016 = sub_policies_2016_health.count
			csv << [policy_id_2015, plan_name_2015, subscriber_2015_hbx_id, subscriber_authority_id, subscriber_2015_name, created_on, updated_on, age, policy_count_2016]
		end
	end
end

dental_count = 0

CSV.open("remaining_renewal_policies_dental.csv", "w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Authority ID", "Subscriber Name", "Created On", "Updated On", "2016 Policies"]
	subscribers.each do |subscriber|
		dental_count += 1
		if dental_count % 1000 == 0
			puts "#{dental_count} dental subscribers reviewed."
		end
		sub_policies_2015_dental = []
		sub_policies_2016_dental = []
		subscriber.policies.each do |policy|
			begin
			next if policy.enrollees.first.coverage_start.year == 2014
			subby = policy.subscriber
			if subby == nil
				policy.enrollees.each do |enrollee|
					if enrollee.rel_code == "self"
						subby = enrollee
					end
				end
			end
			next if (subby.m_id != subscriber.authority_member_id) and (subby.coverage_start.year == 2015)
			if policy.coverage_type == "dental" and subby.coverage_start.year == 2015
				sub_policies_2015_dental.push(policy)
			elsif subby.coverage_start.year == 2015 and policy.aasm_state == "canceled"
				next
			elsif policy.coverage_type == "dental" and subby.coverage_start.year == 2016
				sub_policies_2016_dental.push(policy)
			end
			rescue
				puts policy._id
				next
			end
		end
		next if sub_policies_2015_dental.count == 0
		sub_policies_2015_dental.sort_by! {|policy| policy.subscriber.coverage_start}
		if sub_policies_2015_dental.last.subscriber.coverage_end != nil
			next
		else
			policy_id_2015 = sub_policies_2015_dental.last._id
			plan_name_2015 = sub_policies_2015_dental.last.plan.name
			subscriber_2015_hbx_id = sub_policies_2015_dental.last.subscriber.m_id
			subscriber_authority_id = subscriber.authority_member_id
			subscriber_2015_name = sub_policies_2015_dental.last.subscriber.person.name_full
			created_on = sub_policies_2015_dental.last.created_at
			updated_on = sub_policies_2015_dental.last.updated_at
			policy_count_2016 = sub_policies_2016_dental.count
			csv << [policy_id_2015, plan_name_2015, subscriber_2015_hbx_id, subscriber_authority_id, subscriber_2015_name, created_on, updated_on, policy_count_2016]
		end
	end
end