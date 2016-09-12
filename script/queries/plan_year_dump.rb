# Dumps all plan years for a certain start date, as well as all plan year data for all employers.
require 'csv'

start_date = Date.new(2014,1,1)

plan_years = PlanYear.where(:start_date => start_date)

employers = Employer.all


CSV.open("#{start_date}_plan_years.csv", "w") do |csv|
	csv << ["Plan Year Start", "FEIN", "Employer Name"]
	plan_years.each do |py|
		employer = py.employer
		if employer.plan_years.count == 1
			py_start = py.start_date
			fein = py.employer.fein
			emp_name  = py.employer.name
			csv << [py_start, fein, emp_name]
		elsif employer.plan_years.count == 2
			py_start_1 = employer.plan_years.first.start_date
			py_start_2 = employer.plan_years.last.start_date
			fein = py.employer.fein
			emp_name = py.employer.name
			csv << [py_start_1, fein, emp_name, py_start_2, fein, emp_name]
		elsif employer.plan_years.count == 3
			py_start_1 = employer.plan_years[0].start_date
			py_start_2 = employer.plan_years[1].start_date
			py_start_3 = employer.plan_years[2].start_date
			fein = py.employer.fein
			emp_name = py.employer.name
			csv << [py_start_1, fein, emp_name, py_start_2, fein, emp_name, py_start_3, fein, emp_name]
		elsif employer.plan_years.count > 3
			puts "#{employer.name} has more than 3 plan years"
		end
	end
end

CSV.open("employers_by_plan_year_and_broker.csv", "w") do |csv|
	csv << ["Employer Name", "Employer FEIN", "HBX ID", "Plan Year Start", "Plan Year End", "Broker Name", "Broker NPN"]
	employers.each do |employer|
		employer_name = employer.name
		employer_fein = employer.fein
		hbx_id = employer.hbx_id
		employer.plan_years.each do |py|
			py_start = py.start_date
			py_end = py.end_date
			broker = py.broker
			if broker != nil
				broker_name = broker.full_name
				broker_npn = broker.npn
			end
			csv << [employer_name, employer_fein, hbx_id, py_start, py_end, broker_name, broker_npn]
		end
	end
end