## Cancels policies without transmitting a file. 
require 'csv'

enrollment_group_ids = %w()

policies_to_cancel = Policy.where(:eg_id => {"$in" => enrollment_group_ids})

policies_to_cancel.each do |policy|
	initial_state = policy.aasm_state.to_s
	subscriber_name = policy.subscriber.person.full_name
	policy.aasm_state = "canceled"
	policy.enrollees.each do |enrollee|
		enrollee.coverage_end = enrollee.coverage_start
		enrollee.emp_stat = "terminated"
		enrollee.coverage_status = "inactive"
		enrollee.save
	end
	policy.save
	if policy.save == true
		puts "#{policy.eg_id} - #{initial_state} - #{subscriber_name} => #{policy.aasm_state} --------- succeeded."
	else
		puts "#{policy.eg_id} - #{initial_state} - #{subscriber_name} => #{policy.aasm_state} --------- failed."
	end
end