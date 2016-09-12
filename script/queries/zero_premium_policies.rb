# Returns all policies that have a premium of $0.

effective_date = Date.new(2016,2,29)


potential_policies = Policy.where({:pre_amt_tot => {"$in" => ["0.00", "00.00", "0.0"]},
								   :enrollees => {"$elemMatch" => {:rel_code => "self", :coverage_start => {"$gt" => effective_date}}}})

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("policies_with_zero_premium_#{timestamp}.csv","w") do |csv|
	csv << ["Enrollment Group ID", "AASM State",
		    "Employer Name", "FEIN", 
			"Subscriber Name", "Subscriber HBX ID", 
			"Premium Amount Total", "APTC/Employer Contribution", "Total Responsible Amount",
			"Start Date", "End Date", 
			"Plan Name", "Plan's Year", "Plan HIOS ID", "Created At"]
	potential_policies.each do |policy|
		eg_id = policy.eg_id
		aasm = policy.aasm_state
		if policy.is_shop?
			employer = policy.employer
			fein = employer.fein
			employer_name = employer.name
			contribution = policy.tot_emp_res_amt
		else
			fein = "N/A"
			employer_name = "IVL"
			contribution = policy.applied_aptc
		end
		subscriber_name = policy.subscriber.person.full_name
		subscriber_hbx_id = policy.subscriber.m_id
		total_premium = policy.pre_amt_tot
		responsible_amount = policy.tot_res_amt
		start_date = policy.policy_start
		end_date = policy.policy_end
		plan = policy.plan
		plan_name = plan.name
		plan_year = plan.year
		plan_hios = plan.hios_plan_id
		created_at = policy.created_at
		csv << [eg_id,aasm,employer_name,fein,subscriber_name,subscriber_hbx_id,total_premium,contribution,responsible_amount,start_date,end_date,
				plan_name,plan_year,plan_hios, created_at]
	end
end