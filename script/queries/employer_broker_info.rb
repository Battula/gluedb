# Returns all the brokers associated with an employer.
require 'csv'

CSV.open("employer_broker_info.csv", "w") do |csv|
	csv << ["Employer Name", "Employer HBX ID", "Employer FEIN", "Broker Name", "Broker NPN"]
	#begin
		Employer.all.each do |employer|
			puts employer.name
			employer_name = employer.try(:name)
			employer_hbx_id = employer.try(:hbx_id)
			employer_fein = employer.try(:fein)
			if employer.broker != nil
				broker = employer.try(:broker)
			elsif employer.broker == nil and employer.plan_years.count > 0
				broker = employer.plan_years.last.broker
			end
			broker_name = broker.try(:name_full)
			broker_npn = broker.try(:npn)
			csv << [employer_name, employer_hbx_id, employer_fein, broker_name, broker_npn]
		end
	#rescue
		#binding.pry
	#end
end