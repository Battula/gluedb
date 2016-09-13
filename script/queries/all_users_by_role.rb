require 'csv'

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("all_glue_users_#{timestamp}.csv","w") do |csv|
	csv << ["User","Approved","Role"]
	User.all.each do |user|
		user_email = user.email
		user_approval_status = user.approved
		user_role = user.role
		csv << [user_email,user_approval_status,user_role]
	end
end