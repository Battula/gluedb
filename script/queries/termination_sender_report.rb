require 'csv'

puts "Started at #{Time.now}"

policies = Policy.where(:aasm_state => {"$eq" => "terminated"}, :employer_id => {"$eq" => nil}).no_timeout

@catastrophic_plan_ids = Plan.where(:metal_level => {"$in" => ["catastrophic", "Catastrophic"]}).map(&:id)
@bronze_plan_ids = Plan.where(:metal_level => {"$in" => ["bronze", "Bronze"]}).map(&:id)
@silver_plan_ids = Plan.where(:metal_level => {"$in" => ["silver", "Silver"]}).map(&:id)
@gold_plan_ids = Plan.where(:metal_level => {"$in" => ["gold", "Gold"]}).map(&:id)
@platinum_plan_ids = Plan.where(:metal_level => {"$in" => ["platinum", "Platinum"]}).map(&:id)
@dental_plan_ids = Plan.where(:metal_level => {"$in" => ["dental", "Dental"]}).map(&:id)

def return_metal_level(plan_id)
	if @catastrophic_plan_ids.include? plan_id
		return 'catastrophic'
	elsif @bronze_plan_ids.include? plan_id
		return 'bronze'
	elsif @silver_plan_ids.include? plan_id
		return 'silver'
	elsif @gold_plan_ids.include? plan_id
		return 'gold'
	elsif @platinum_plan_ids.include? plan_id
		return 'platinum'
	elsif @dental_plan_ids.include? plan_id
		return 'dental'
	end
end

def parse_end_date(edi_body)
	edi_array = edi_body.split("~")
	edi_array.each do |edi_line|
		if edi_line.include? "*349*"
			end_date = edi_line.gsub("DTP*349*D8*","").to_date
			return end_date
		end
	end
end

def parse_file_name_for_carrier(filename)
	if filename.include? "DCHBX"
		return "DC Health Link"
	elsif filename.include? "DDPA"
		return "Delta Dental"
	elsif filename.include? "DTGA"
		return "Dentegra"
	elsif filename.include? "DMND"
		return "Dominion"
	elsif filename.include? "GARD"
		return "Guardian"
	elsif filename.include? "BLHI"
		return "BestLife"
	elsif filename.include? "META"
		return "MetLife"
	elsif filename.include? "GHMSI"
		return "CareFirst"
	elsif filename.include? "AHI"
		return "Aetna"
	elsif filename.include? "UHIC"
		return "United Health Care"
	elsif filename.include? "KFMASI"
		return "Kaiser"
	end
end

def aptc_exists?(policy)
	if policy.aptc_credits.size > 0
		return "Yes"
	elsif policy.applied_aptc.to_f > 0.to_f
		return "Yes"
	else
		return "No"
	end
end

count = 0

total_count = policies.size

CSV.open("termination_sender_report.csv", "w") do |csv|
	csv << ["Subscriber", "HBX ID", "Policy ID", "Enrollment Group ID","Metal Level", "Start Date", "Termination Date", "Date Termination Sent", "APTC?", "Sender"]
	policies.each do |policy|
		count += 1
		if count % 1000 == 0
			puts "#{Time.now} - #{count}"
		end
		next if policy.subscriber.coverage_start.year == 2016
		correct_files = []
		policy_end_date = policy.subscriber.coverage_end
		policy.edi_transaction_sets.each do |edi|
			edi_body = edi.body.read
			if edi_body.include? "*349*"
				edi_end_date = parse_end_date(edi_body)
				if policy_end_date == edi_end_date
					correct_files.push(edi)
				end 
			end # Checks for termination EDI
		end # Goes through each of the EDI transactions 
			if correct_files.size > 0
				subscriber = policy.subscriber.person.full_name
				hbx_id = policy.subscriber.m_id
				policy_id = policy._id
				eg_id = policy.eg_id
				metal_level = return_metal_level(policy.plan_id)
				start_date = policy.subscriber.coverage_start.to_s
				end_date = policy.subscriber.coverage_end.to_s
				termination_file = correct_files.first
				date_sent = termination_file.submitted_at
				aptc = aptc_exists?(policy)
				sender = termination_file.transmission.sender.name
				csv << [subscriber,hbx_id, policy_id, eg_id, metal_level, start_date,end_date,date_sent, aptc, sender]
			elsif correct_files.size == 0
				subscriber = policy.subscriber.person.full_name
				hbx_id = policy.subscriber.m_id
				policy_id = policy._id
				eg_id = policy.eg_id
				metal_level = return_metal_level(policy.plan_id)
				start_date = policy.subscriber.coverage_start.to_s
				end_date = policy.subscriber.coverage_end.to_s
				aptc = aptc_exists?(policy)
				date_sent = "No Matching EDI Found"
				termination_file = "No Matching EDI Found"
				csv << [subscriber,hbx_id, policy_id, eg_id, metal_level, start_date,end_date,date_sent, aptc, termination_file]
			end # Lazily evaluate multiple transacations to decrease processing time.
	end # Goes through all the policies 
end # Writes to a Csv FILE

puts "ended at #{Time.now}"
