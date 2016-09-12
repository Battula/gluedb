# Removes cancels from policies.
require 'csv'

eg_ids = %w()

policies_to_clean = Policy.where(:eg_id => {"$in" => eg_ids})

old_version = File.new("old_version.txt", "w")

new_version = File.new("new_version.txt", "w")

policies_to_clean.each do |policy|
	previous_version_number = policy.version - 1
	if previous_version_number > 0
		policy.versions.each do |vers|
			if vers.version == previous_version_number
				old_version.puts vers.try(:aasm_state)
				old_version.puts "This version has #{vers.try(:enrollees).try(:count)} enrollee(s)."
				old_version.puts policy.eg_id
				vers.enrollees.each do |enrollee|
					if enrollee.coverage_end != nil
						old_version.puts "#{enrollee.try(:m_id)} - #{enrollee.try(:coverage_start)} - #{enrollee.try(:coverage_end)}"
					end
				end
				old_version.puts "-----------------------"
			end
		end
	end
	new_version.puts policy.aasm_state
	new_version.puts "This version has #{policy.enrollees.count} enrollee(s)."
	new_version.puts policy.eg_id
	policy.enrollees.each do |enrollee|
		begin
		if enrollee.coverage_end > enrollee.coverage_start
			new_version.puts "#{enrollee.m_id} - #{enrollee.try(:coverage_start)} - #{enrollee.try(:coverage_end)}"
		end
		rescue
			next
		end
	end
	new_version.puts "-----------------------"
end

policies_to_clean.each do |policy|
	next if policy.canceled? == false
	policy.aasm_state = "submitted"
	policy.enrollees.each do |enrollee|
		enrollee.coverage_end = nil
		enrollee.save
	end
	policy.save
	puts policy.eg_id
	puts policy.enrollees
	puts "____________________"
end