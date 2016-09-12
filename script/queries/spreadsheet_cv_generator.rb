# Takes a CSV as input and creates initial enrollment CVs.
require 'csv'
require 'bigdecimal'

filename = ""

def does_ssn_exist?(ssn)
	if Person.where("members.ssn" => ssn.to_s).count > 0
		return ssn_person = Person.where("members.ssn" => ssn).first.name_full
	else
		return false
	end
end

def does_name_dob_exist?(first_name, last_name, dob)
	if Person.where("members.dob" => dob, :name_first => first_name, :name_last => last_name).count > 0
		return dob_person = Person.where("members.dob" => dob, :name_first => first_name, :name_last => last_name).first.name_full
	else 
		return false
	end
end

def does_enrollee_exist(person,policy)
	enrollee_hbx_ids = policy.enrollees.map(&:m_id)
	hbx_id = person.authority_member_id.to_s
	if enrollee_hbx_ids.include?(hbx_id)
		return true
	else
		return false
	end
end

CSV.foreach(filename, headers: true) do |row|
	begin
		data_row = row.to_hash
		next if data_row["Market"] == nil
		new_person = Person.where(authority_member_id: data_row["HBX ID"].to_s).first
		if new_person == nil ## Let's validate that this person exists...
			## First, create the person object.
			new_person = Person.new
			new_person.name_first = data_row["First Name"]
			new_person.name_middle = data_row["Middle Name"]
			new_person.name_last = data_row["Last Name"]
			new_person.name_full = "#{data_row["First Name"]} #{data_row["Middle Name"]} #{data_row["Last Name"]}"
			new_person.authority_member_id = data_row["HBX ID"]
			new_person.save	
			

			## Second, create the addresses. 
			addy = Address.new
			addy.address_type = "home"
			addy.address_1 = data_row["Address 1"]
			addy.address_2 = data_row["Address 2"]
			addy.city = data_row["City"]
			addy.state = data_row["State"]
			addy.zip = data_row["Zip"]			

			## Add the address to the person. 
			new_person.addresses.push(addy)
			addy.save
			new_person.save	

			if data_row["Email"] != nil
				email = Email.new
				email.email_type = "home"
				email.email_address = data_row["Email"]
				new_person.emails.push(email)
				email.save
				new_person.save
			end	

			if data_row["Phone"] != nil
				telephone = Phone.new
				telephone.phone_type = "home"
				telephone.phone_number = data_row["Phone"].to_s.gsub("(","").gsub(")","").gsub("-","").strip
				new_person.phones.push(telephone)
				telephone.save
				new_person.save
			end	

			## Add the member object - this has demographic information.
			mmr = Member.new
			mmr.hbx_member_id = data_row["HBX ID"].strip
			mmr.dob = data_row["DOB"].to_date
			mmr.ssn = data_row["SSN"].gsub("-","")
			mmr.gender = data_row["Gender"].downcase		

			## Add the member object to the person.
			new_person.members.push(mmr)
			new_person.save	
		end

		## Create the policy object
		new_policy = Policy.where(:eg_id => data_row["Enrollment Group ID"].to_s).first
		if new_policy == nil
			new_policy = Policy.new
			new_policy.eg_id = data_row["Enrollment Group ID"].to_s	
			

			## Add a plan
			year = data_row["Benefit Begin Date"].to_date.year.to_s
			new_plan = Plan.where(hios_plan_id: data_row["HIOS Id (auto)"], year: year).first
			new_policy.plan = new_plan
			new_policy.carrier = new_plan.carrier
			new_policy.save
		end		

		## Add an enrollee if they don't exist.
		if does_enrollee_exist(new_person,new_policy) == false
			new_policy_enrollee = Enrollee.new
			new_policy_enrollee.m_id = data_row["HBX ID"]
			new_policy_enrollee.rel_code = data_row["Relationship"].downcase
			new_policy_enrollee.coverage_start = data_row["Benefit Begin Date"].to_date
			new_policy_enrollee.pre_amt = data_row["Premium"].to_d
			new_policy.enrollees.push(new_policy_enrollee)
			new_policy.save
		end

		## Add an Employer
		if data_row["Sponsor Name"] != nil
			fein = data_row["FEIN"].gsub("-","")
			employer_id = Employer.where(fein: fein).first._id
			new_policy.employer_id = employer_id
			new_policy.save
		end			

		## Calculate the premiums
		# m_ids = []
		# new_policy.enrollees.each do |en|
		# 	m_ids << en.m_id
		# end
		# member_repo = Caches::MemberCache.new(m_ids)
		# calc = Premiums::PolicyCalculator.new(member_repo)
		# calc.apply_calculations(new_policy)
		new_policy.pre_amt_tot = data_row["Premium Tot (auto)"].to_d
		if new_policy.is_shop?
			new_policy.tot_emp_res_amt = data_row["Employer Contribution/AptC"].gsub("$","").strip.to_d
			new_policy.tot_res_amt = new_policy.pre_amt_tot - new_policy.tot_emp_res_amt
		end
		new_policy.save

		## Add a Responsible Party
		if data_row["Responsible Party"] != nil
			resp_party_per = Person.new
			resp_party_per.name_full = data_row["Responsible Party"]
			name = resp_party_per.name_full
			name_array = name.split
			if name_array.count == 2
				resp_party_per.name_first = name_array.first
				resp_party_per.name_last = name_array.last
			elsif name_array.count == 3
				resp_party_per.name_first = name_array[0]
				resp_party_per.name_middle = name_array[1]
				resp_party_per.name_last = name_array[2]
			elsif name_array.count == 4
				resp_party_per.name_first = name_array[0]
				resp_party_per.name_middle = name_array[1]
				resp_party_per.name_last = "#{name_array[2]} #{name_array[3]}"
			end
			resp_party_per.save

			resp_party_per.addresses.push(addy)
			resp_party_per.save			

			resp_party = ResponsibleParty.new
			resp_party.entity_identifier = "responsible party"
			resp_party_per.responsible_parties.push(resp_party)
			resp_party.save
			resp_party_per.save			

			new_policy.responsible_party_id = resp_party._id
			new_policy.save
		end		

		## Generate a CV
		subscriber_id = new_policy.subscriber.m_id
		enrollee_list = new_policy.enrollees.all
		all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
		subby = new_policy.subscriber
		edi_type = data_row["Operation Type"]
		edi_reason = data_row["Reason"]
		out_file = File.open(File.join("initial_enrollments_generated", "#{subby.coverage_start.month}-#{subby.coverage_start.day} Renewal - #{new_policy.market} - #{subby.person.name_full} - #{new_policy.coverage_type}.xml"), 'w')
		ie_cv = CanonicalVocabulary::MaintenanceSerializer.new(
		          			new_policy,
		          			edi_type,
		          			edi_reason,
		          			all_ids,
		          			all_ids
		        			)
		out_file.write(ie_cv.serialize)
		out_file.close
	rescue Exception=>e
		binding.pry
	end
end