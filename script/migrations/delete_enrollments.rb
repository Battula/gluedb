## ONLY USE THIS CODE IN THE MOST DIRE OF EMERGENCIES.

puts "Current Policy Count - #{Policy.all.size}"

eg_ids = Array.new

File.readlines("policies_to_delete.txt").each do |line|
    eg_ids.push(line.to_s.strip)
end

puts "You have #{eg_ids.size} enrollment group IDs"

policies_to_delete = Policy.where(:eg_id => {"$in" => eg_ids}).delete

puts "Afterwards Policy Count - #{Policy.all.size}"