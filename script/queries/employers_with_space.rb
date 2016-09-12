# Returns employers who have a space in their name. This is occasionally useful in instances where B2B problems are occurring due to spaces.
require 'csv'

employer_list = File.new("employer_with_bad_space.txt", "w")

Employer.all.each do |employer|
	name = employer.name
	if name =~ /\s$/
		employer_list.puts "'#{name}'"
		name.gsub!(/\s$/,"")
		employer_list.puts "'#{name}'"
	elsif name =~ /^\s/
		employer_list.puts "'#{name}'"
		name.gsub!(/^\s/,"")
		employer_list.puts "'#{name}'"
	end
end