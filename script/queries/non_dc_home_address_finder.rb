require 'pry'
require 'csv'

puts "#{Time.now} loading people."

all_people = Person.all.to_a

puts "#{Time.now} - #{all_people.count} people loaded."

non_dc_people = []

all_people.each do |person|
	person.addresses.each do |address|
		if address.address_type == "home" and address.state != "DC"
			non_dc_people.push(person)
		end
	end
end

puts "#{Time.now} - #{non_dc_people.count} people who don't live in DC."

non_shop_people = []

non_dc_people.each do |person|
	if person.policies.all? {|policy| policy.employer_id == nil}
		non_shop_people.push(person)
	end
end

puts "#{Time.now} - #{non_shop_people.count} who don't live in DC and have no SHOP policies."

start_date = Date.new(2015,1,1)

non_shop_2015_people = []

non_shop_people.each do |person|
	if person.policies.any? {|policy| policy.enrollees.first.coverage_start >= start_date}
		non_shop_2015_people.push(person)
	end
end

CSV.open("non_dc_people.csv", "w") do |csv|
	csv << ["HBX ID", "Name", "Address 1", "Address 2", "City", "State", "Zip", "Updated By"]
	non_shop_2015_people.each do |person|
		hbx_id = person.authority_member_id
		name = person.name_full
		address = person.addresses.where(:address_type == "home")
		address_1 = address.first.address_1
		address_2 = address.first.try(:address_2)
		city = address.first.city
		state = address.first.state
		zip = address.first.zip
		updated_by = person.try(:updated_by)
		csv << [hbx_id, name, address_1, address_2, city, state, zip, updated_by]
	end
end