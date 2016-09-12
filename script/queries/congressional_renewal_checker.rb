require 'csv'

congress_feins = %w()

congress_employers_ids = Employer.where(:fein => {"$in" => congress_feins}).map(&:id)

def is_congressional?(policy,congress_employers_ids)
	if policy.employer_id == congress_employers_ids[0]
		return true
	elsif policy.employer_id == congress_employers_ids[1]
		return true
	elsif policy.employer_id == congress_employers_ids[2]
		return true
	else
		return false
	end
end

start_date = Date.new(2015,1,1)

congressional_policies_2015 = Policy.where(:employer_id => {"$in" => congress_employers_ids},
										   :aasm_state => {"$ne" => "canceled"},
											:enrollees => {"$elemMatch" => {:rel_code => "self", 
																			:coverage_start => {"$gte" => start_date}}})

congressional_subscribers = []

puts "#{congressional_policies_2015.count} subscribers to check for."

count = 0

congressional_policies_2015.each do |congress_policy|
	count += 1
	if count % 1000 == 0
		puts count
	end
	if congress_policy.subscriber != nil
		congressional_subscribers.push(congress_policy.subscriber.person)
	else
		congress_policy.enrollees.each do |enrollee|
			if enrollee.rel_code == "self"
				congressional_subscribers.push(enrollee.person)
			end
		end
	end
end

congressional_subscribers.uniq!

puts "#{congressional_subscribers.count} to go!"

count = 0

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("congressional_subscribers_plans_#{timestamp}.csv", "w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Name", "Subscriber SSN", "Created On", "Updated On", "2016 Policy?"]
	congressional_subscribers.each do |cong_sub|
		count += 1
		if count % 1000 == 0
			puts count
		end
		cong_sub_policies_2015 = []
		cong_sub_policies_2016 = []
		cong_sub.policies.each do |cong_pol|
			next if cong_pol.subscriber.coverage_start.year == 2014
			next if cong_pol.employer_id == nil
			next if is_congressional?(cong_pol,congress_employers_ids) == false
			if cong_pol.subscriber.coverage_start.year == 2015
				cong_sub_policies_2015.push(cong_pol)
			elsif cong_pol.subscriber.coverage_start.year == 2016
				cong_sub_policies_2016.push(cong_pol)
			end
		end
		next if cong_sub_policies_2015.count == 0
		if cong_sub_policies_2015.count == 1
			cong_sub_policies_2015.each do |cong_pol|
				if cong_pol.subscriber.coverage_end != nil
					next
				else
					policy_id_2015 = cong_pol._id
					plan_2015 = cong_pol.plan.name
					sub_hbx_id = cong_pol.subscriber.m_id
					sub_name = cong_pol.subscriber.person.name_full
					sub_ssn = cong_pol.subscriber.person.members.first.ssn
					created_on = cong_pol.created_at
					updated_on = cong_pol.updated_at
					if cong_sub_policies_2016.count == 0
						policy_2016 = "FALSE"
						csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, policy_2016]
					elsif cong_sub_policies_2016.count > 0
						policy_2016 = "TRUE"
						csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, policy_2016]
					end
				end
			end
		elsif cong_sub_policies_2015.count > 1
			cong_sub_policies_2015.sort_by! {|policy| policy.subscriber.coverage_start}
			if cong_sub_policies_2015.last.subscriber.coverage_end != nil
				next
			else
				cong_pol = cong_sub_policies_2015.last
				policy_id_2015 = cong_pol._id
				plan_2015 = cong_pol.plan.name
				sub_hbx_id = cong_pol.subscriber.m_id
				sub_name = cong_pol.subscriber.person.name_full
				sub_ssn = cong_pol.subscriber.person.members.first.ssn
				created_on = cong_pol.created_at
				updated_on = cong_pol.updated_at
				if cong_sub_policies_2016.count == 0
					policy_2016 = "FALSE"
					csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, policy_2016]
				elsif cong_sub_policies_2016.count > 0
					policy_2016 = "TRUE"
					csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, policy_2016]
				end
			end
		end
	end
end

