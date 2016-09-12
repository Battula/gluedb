## This script is designed to find people who are responsible parties and find potential matches. 

responsible_parties = Person.where(:responsible_parties => {"$ne" => nil})

total_count = responsible_parties.count

count = 0

responsible_parties.each do |responsible_party|
	first_name = responsible_party.name_first
	last_name = responsible_party.name_last
	potential_matches = Person.where(name_first: first_name, name_last: last_name, authority_member_id: {"$ne" => nil}).to_a
	if potential_matches.count != 0
		count += 1
		puts "#{first_name} #{last_name}"
		puts "--------------------------"
		puts potential_matches.inspect
		puts "-"*100
	end

end

puts "#{count} responsible parties have potential person matches out of a total of #{total_count}."