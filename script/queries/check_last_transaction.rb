# Returns the last transaction on any policy, specified by enrollment group ID. 
require 'csv'

enrollment_group_ids = %w()

policies = Policy.where(:eg_id => {"$in" => enrollment_group_ids})

file_names = []

CSV.open("last_transaction.csv","w") do |csv|
	csv << ["Enrollment Group ID","File Name"]
	policies.all.each do |policy|
		first_transaction = policy.transaction_set_enrollments.first
		bgn02 = first_transaction.bgn02
		filename = first_transaction.body.to_s.gsub("uploads/#{bgn02}_","")
		csv << [policy.eg_id,filename]
	end
end
