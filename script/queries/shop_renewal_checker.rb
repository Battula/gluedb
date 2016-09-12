# Checks if employees have a renewal for their SHOP policy. Takes an array of FEINs as input. 
require 'csv'

shop_feins = %w()

shop_employers_ids = Employer.where(:fein => {"$in" => shop_feins}).map(&:id)

def is_congressional?(policy)
	congress_feins = %w()
	congress_employers_ids = Employer.where(:fein => {"$in" => congress_feins}).map(&:id)
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

renewal_start_date = Date.new(2016,1,1)

shop_policies_2015 = Policy.where(:employer_id => {"$in" => shop_employers_ids},
										   :aasm_state => {"$ne" => "canceled"},
											:enrollees => {"$elemMatch" => {:rel_code => "self", 
																			:coverage_start => {"$gte" => start_date, 
																								"$lt" => renewal_start_date}}})

shop_subscribers = []

puts "#{shop_policies_2015.count} subscribers to check for."

count = 0

shop_policies_2015.each do |shop_policy|
	count += 1
	if count % 1000 == 0
		puts count
	end
	if shop_policy.subscriber != nil
		shop_subscribers.push(shop_policy.subscriber.person)
	else
		shop_policy.enrollees.each do |enrollee|
			if enrollee.rel_code == "self"
				shop_subscribers.push(enrollee.person)
			end
		end
	end
end

shop_subscribers.uniq!

puts "#{shop_subscribers.count} to go!"

count = 0

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("shop_subscribers_plans_#{timestamp}.csv", "w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Name", "Subscriber SSN", "Created On", "Updated On", "Employer Name", "2016 Policy?"]
	shop_subscribers.each do |shop_sub|
		count += 1
		if count % 1000 == 0
			puts count
		end
		shop_sub_policies_2015 = []
		shop_sub_policies_2016 = []
		shop_sub.policies.each do |shop_pol|
			next if shop_pol.subscriber.coverage_start.year == 2014
			next if shop_pol.employer_id == nil
			next if is_congressional?(shop_pol) == true
			if shop_pol.subscriber.coverage_start.year == 2015
				shop_sub_policies_2015.push(shop_pol)
			elsif shop_pol.subscriber.coverage_start.year == 2016
				shop_sub_policies_2016.push(shop_pol)
			end
		end
		next if shop_sub_policies_2015.count == 0
		if shop_sub_policies_2015.count == 1
			shop_sub_policies_2015.each do |shop_pol|
				if shop_pol.subscriber.coverage_end != nil
					next
				else
					policy_id_2015 = shop_pol._id
					plan_2015 = shop_pol.plan.name
					sub_hbx_id = shop_pol.subscriber.m_id
					sub_name = shop_pol.subscriber.person.name_full
					sub_ssn = shop_pol.subscriber.person.members.first.ssn
					created_on = shop_pol.created_at
					updated_on = shop_pol.updated_at
					emp_name = shop_pol.employer.name
					if shop_sub_policies_2016.count == 0
						policy_2016 = "FALSE"
						csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, emp_name, policy_2016]
					elsif shop_sub_policies_2016.count > 0
						policy_2016 = "TRUE"
						csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, emp_name, policy_2016]
					end
				end
			end
		elsif shop_sub_policies_2015.count > 1
			shop_sub_policies_2015.sort_by! {|policy| policy.subscriber.coverage_start}
			if shop_sub_policies_2015.last.subscriber.coverage_end != nil
				next
			else
				shop_pol = shop_sub_policies_2015.last
				policy_id_2015 = shop_pol._id
				plan_2015 = shop_pol.plan.name
				sub_hbx_id = shop_pol.subscriber.m_id
				sub_name = shop_pol.subscriber.person.name_full
				sub_ssn = shop_pol.subscriber.person.members.first.ssn
				created_on = shop_pol.created_at
				updated_on = shop_pol.updated_at
				emp_name = shop_pol.employer.name
				if shop_sub_policies_2016.count == 0
					policy_2016 = "FALSE"
					csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, emp_name, policy_2016]
				elsif shop_sub_policies_2016.count > 0
					policy_2016 = "TRUE"
					csv << [policy_id_2015, plan_2015, sub_hbx_id, sub_name, sub_ssn, created_on, updated_on, emp_name, policy_2016]
				end
			end
		end
	end
end