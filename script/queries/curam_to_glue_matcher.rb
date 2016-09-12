require 'csv'
require 'ostruct'

# This script takes a spreadsheet provided with Curam Data and finds glue policies matching that. 
# It was used for 2015 -> 2016 passive renewals for assisted policies.

filename = "enrollment_data_102815.csv"

start_date = Date.new(2015,1,1)

def valid_policy?(pol)
  return false if pol.rejected? || pol.has_no_enrollees? || pol.canceled? || pol.is_shop? || pol.terminated?
  true
end

def duplicated_policies?(policies)
	aptcs = []
	hios_variants = []
	start_dates = []
	plan_ids = []
	enrollee_count = []
	subscribers = []
	policies.each do |policy|
		aptcs.push(policy.applied_aptc)
		hios_variants.push(policy.plan.hios_plan_id)
		plan_ids.push(policy.plan_id)
		enrollee_count.push(policy.enrollees.count)
		policy.enrollees.each do |enrollee|
			if enrollee.rel_code == "self"
				start_dates.push(enrollee.coverage_start)
				subscribers.push(enrollee.m_id)
			else
				next
			end
		end
	end

	aptcs.uniq!
	hios_variants.uniq!
	start_dates.uniq!
	plan_ids.uniq!
	enrollee_count.uniq!
	subscribers.uniq!
	return_hash = {"aptc" => "#{aptcs.count} aptc values",
				   "hios_variants" => "#{hios_variants.count} hios variants", 
				   "start_dates" => "#{start_dates.count} start dates",
				   "plans" => "#{plan_ids.count} different plans",
				   "enrollee count" => "#{enrollee_count.count} group sizes",
				   "subscriber count" => "#{subscribers.count} subscribers" }
	if aptcs.count == 1 and 
		hios_variants.count == 1 and 
		start_dates.count == 1 and 
		plan_ids.count == 1 and 
		enrollee_count.count == 1 and
		subscribers.count == 1
		return true
	else
		return return_hash
	end
end

def is_dental?(policy)
	return true if policy.coverage_type == "dental"
	return false if policy.coverage_type == "health"
end

def multiple_policies_winner(policies)
	valid_policies = []
	if policies.is_a? Policy
		policies = [policies]
	end
	policies.each do |policy|
		if valid_policy?(policy) == true and is_dental?(policy) == false
			valid_policies.push(policy)
		end
	end
	if valid_policies.count == 1
		return policy_id = valid_policies.last._id
	elsif valid_policies.count > 1
		if duplicated_policies?(valid_policies) == true
			return policy_id = valid_policies.last._id
		else
			return duplicated_policies?(valid_policies)
		end
	elsif valid_policies.count == 0
		return policy_id = "No Valid Policies"
	end
end

CSV.open("matched_policies.csv", "w") do |csv|
	CSV.foreach(filename, headers: true) do |row|
	  curam_row = row.to_hash
	  ssn_row = curam_row["ssn"]
	  dob_row = Date.strptime(curam_row["dob"], "%m/%d/%Y")
	  first_name = curam_row["firstname"]
	  plan_name = curam_row["lasthealthplan"]
	  person = Person.unscoped.where({"members.ssn" => ssn_row}).and({"members.dob" => dob_row}).and({"name_first" => first_name}).to_a.first
	  if person == nil
	  	fname = row["firstname"]
	  	lname = row["lastname"]
	  	person_name = "#{fname} #{lname}"
	  	policy_id = "Person Not Found"
	  	plan_name = "Person Not Found"
	  	policy_count = 0
	  	csv << row.push(policy_id)
	  	next
	  end
	  person_name = person.name_full
	  policies_to_analyze = person.policies.all
	  matched_policies = []
	  	policies_to_analyze.each do |policy|
		  	if policy.enrollees.first.coverage_start >= start_date
		  		if policy.plan.name == plan_name
		  			matched_policies.push(policy)
		  		end # Ends plan name evaluator.
		  	end # Ends start date evaluator. 
		  end # Ends policy analyzer. 
		  if matched_policies.count == 1
		  	policy_id = matched_policies.last._id
		  	csv << row.push(policy_id)
		  else
		  	csv << row.push(multiple_policies_winner(matched_policies))
		  end # Ends match_policies.count
	end # Ends CSV.foreach()

end # Ends CSV.open()