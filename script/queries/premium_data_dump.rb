# Returns premium data for all policies with a certain start date or greater. 
require 'csv'

start_date = Date.new(2015,8,1)

shop_policies = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self",:coverage_start => {"$gte" => start_date}}},
							  :employer_id => {"$ne" => nil}})

timestamp = Time.now.strftime('%Y%m%d%H%M')

def to_dollars(premium_amt_in_cents)
	dollar_amt = premium_amt_in_cents.to_d/100.to_d
	return "$#{dollar_amt}"
end

tc = shop_policies.size

puts "#{Time.now} - #{tc}"

count = 0

CSV.open("shop_policies_premium_data_#{timestamp}.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "Policy ID", "State", 
			"Employer Name", "Employer FEIN", 
			"Subscriber Name", "Subscriber HBX ID",
			"Coverage Start", "Coverage End",
			"Premium Payments"]
	shop_policies.each do |policy|
		count += 1
		puts "#{Time.now} - #{count}" if count % 1000 == 0
		eg_id = policy.eg_id
		policy_id = policy._id
		state = policy.aasm_state
		employer = policy.employer
		unless employer == nil
			employer_name = employer.name
			employer_fein = employer.fein
		else
			employer_name = "Employer Not Found"
			employer_fein = ""
		end
		subscriber = policy.subscriber
		subscriber_name = subscriber.person.full_name
		subscriber_hbx_id = subscriber.m_id
		effective_date = subscriber.coverage_start
		termination_date = subscriber.coverage_end
		payments_count = policy.premium_payments.size
		csv_row = []
		if payments_count == 0
			premium_payments = "No Premium Payments"
			csv_row = csv_row + [eg_id,policy_id,state,
					employer_name,employer_fein,
					subscriber_name,subscriber_hbx_id,
					effective_date,termination_date,
					premium_payments]
		elsif payments_count == 1
			premium_payments = policy.premium_payments.first
			premium_start = premium_payments.start_date
			premium_end = premium_payments.end_date
			premium_amt = to_dollars(premium_payments.pmt_amt)
			csv_row = csv_row + [eg_id,policy_id,state,
					employer_name,employer_fein,
					subscriber_name,subscriber_hbx_id,
					effective_date,termination_date,
					"#{premium_start}-#{premium_end}: #{premium_amt}"]
		else
			premium_payments = policy.premium_payments
			pp_array = Array.new
			premium_payments.each do |premium_payment|
				premium_start = premium_payment.start_date
				premium_end = premium_payment.end_date
				premium_amt = to_dollars(premium_payment.pmt_amt)
				pp_array.push("#{premium_start}-#{premium_end}: #{premium_amt}")
			end
			pp_array_size = pp_array.size
			csv_row = csv_row + [eg_id,policy_id,state,
					employer_name,employer_fein,
					subscriber_name,subscriber_hbx_id,
					effective_date,termination_date] + pp_array
		end
		csv << csv_row
	end
end