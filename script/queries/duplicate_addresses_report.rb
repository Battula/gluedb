require 'csv'

policies = Policy.no_timeout.where(
   :enrollees => {"$elemMatch" =>
      {:rel_code => "self",
            :coverage_start => {"$gt" => Date.new(2015,12,31)}}})

timestamp = Time.now.strftime('%Y%m%d%H%M')

def compare_addresses(home_address,mailing_address)
	cleaned_home_address = clean_fields(home_address)
	cleaned_mailing_address = clean_fields(mailing_address)
	full_home_address = cleaned_home_address.full_address.downcase
	full_mailing_address = cleaned_mailing_address.full_address.downcase
	if full_home_address == full_mailing_address
		return true
	end
end

def clean_fields(address)
	address.address_1 = address.address_1.try(:strip)
	address.address_2 = address.address_2.try(:strip)
	address.city = address.city.try(:strip)
	address.state = address.state.try(:strip)
	address.zip = address.zip.try(:strip)
	return address
end

CSV.open("2016_enrollments_with_multiple_addresses_#{timestamp}.csv", "w") do |csv|
	csv << ["Glue Policy ID", "Enrollment Group ID", "Subscriber", "HBX ID", "Home Address","","","","", "Mailing Address"]
	csv << ["","","","","Address 1","Address 2","City","State","Zip","Address 1","Address 2","City","State","Zip"]
	policies.each do |policy|
		next if policy.subscriber.person.addresses.size < 2
		policy_id = policy._id
		eg_id = policy.eg_id
		subscriber = policy.subscriber.person
		subscriber_name = subscriber.full_name
		subscriber_hbx_id = policy.subscriber.m_id
		home_address = subscriber.home_address
		mailing_address = subscriber.mailing_address
		unless home_address == nil || mailing_address == nil
			address_comparison = compare_addresses(home_address,mailing_address)
			if address_comparison == true
				csv << [policy_id,eg_id,subscriber_name,subscriber_hbx_id,
					home_address.try(:address_1),home_address.try(:address_2),home_address.try(:city),home_address.try(:state),home_address.try(:zip),
					mailing_address.try(:address_1),mailing_address.try(:address_2),mailing_address.try(:city),mailing_address.try(:state),mailing_address.try(:zip)]
				end
		else
			next
		end
	end
end