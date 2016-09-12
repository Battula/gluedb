# This script returns a CSV with IVL policies that have a start date in 2014 but a termination date after 1/1/2015. 
# This script can be modified for other dates as well.

require 'csv'

start_date = Date.new(2014,12,31)

policies_wrong_term_date = Policy.where(:enrollees => {"$elemMatch" => 
											{:rel_code => "self",
											 :coverage_start => {"$lte" => start_date},
											 :coverage_end => {"$gt" => start_date}
											 }
											 },:employer_id => nil)

CSV.open("wrong_term_date.csv", "w") do |csv|
	csv << ["Policy ID", "Enrollment Group ID", "First Name", "Last Name", "HBX ID", "Start Date", "End Date", "Updated By"]
	policies_wrong_term_date.each do |policy|
		policy_id = policy._id
		eg_id = policy.eg_id
		updated_by = policy.try(:updated_by)
		policy.enrollees.each do |enrollee|
			first_name = enrollee.person.name_first
			last_name = enrollee.person.name_last
			hbx_id = enrollee.m_id
			start_date = enrollee.coverage_start
			end_date = enrollee.coverage_end
			csv << [policy_id, eg_id, first_name, last_name, hbx_id, start_date, end_date, updated_by]
		end
	end
end