require 'csv'

policies_2016 = Policy.where(:enrollees => {"$elemMatch" => {
							 	:rel_code => "self",
							 	:coverage_start => {"$gt" => Date.new(2015,12,31)}
							 	}})


aptc_policies = []

policies_2016.each do |policy|
	if policy.applied_aptc != 0.to_d
		aptc_policies.push(policy)
	end
end

variants = ["02","03","04","05","06"]

csr_variant_plans_2016 = Plan.where(:csr_variant_id => {"$in" => variants}, year: 2016).map(&:id)

csr_policies = Policy.where(:enrollees => {"$elemMatch" => {
							 	:rel_code => "self",
							 	:coverage_start => {"$gt" => Date.new(2015,12,31)}
							 	}},
							 :plan_id => {"$in" => csr_variant_plans_2016})

timestamp = Time.now.strftime('%Y%m%d%H%M')

assistance_policies = (aptc_policies + csr_policies).uniq

def return_ssn(person,enrollee_hbx_id)
	correct_member = person.members.detect{|member| member.hbx_member_id == enrollee_hbx_id.to_s}
	return correct_member.try(:ssn)
end

def return_emails(person)
	email_addresses = person.emails.map(&:email_address)
	if email_addresses.size == 1
		return email_addresses.first
	elsif email_addresses.size > 1
		return email_addresses.join(',')
	end
end

puts "#{Time.now} - #{assistance_policies.size}"

Caches::MongoidCache.with_cache_for(Plan) do
	CSV.open("2016_aptc_policies_#{timestamp}.csv", "w") do |csv|
		csv << ["Enrollment Group ID", "Glue Policy ID", "State", "Name", "HBX ID", "SSN",
				"Plan Name", "Plan Metal", "HIOS ID", 
				"Relationship", "APTC Amount", "Responsible Party","Start Date", "End Date", "Subscriber's Email(s)"]
		assistance_policies.each do |policy|
			eg_id = policy.eg_id
			policy_id = policy._id
			aptc_amount = policy.applied_aptc
			plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
			plan_name = plan.name
			plan_metal = plan.metal_level
			plan_hios = plan.hios_plan_id
			state = policy.aasm_state
			responsible_party = policy.has_responsible_person?
			emails = return_emails(policy.subscriber.person)
			policy.enrollees.each do |enrollee|
				person = enrollee.person
				name = person.full_name
				hbx_id = enrollee.m_id
				ssn = return_ssn(person,hbx_id)
				relationship = enrollee.rel_code
				start_date = enrollee.coverage_start
				end_date = enrollee.coverage_end
				csv << [eg_id,policy_id,state,
						name,hbx_id,ssn,
						plan_name,plan_metal,plan_hios,
						relationship,aptc_amount, responsible_party,start_date,end_date,emails]
			end
		end # Ends policies loop
	end # Closes CSV
end # Ends MongoidCache

puts "Completed at #{Time.now}"