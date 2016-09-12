clone_start_date = Date.new(2015,8,1) # This is the 2014 date plan year start for who needs to be renewed.

new_start_date = Date.new(2016,8,1) # This is the new plan year.
new_end_date = Date.new(2017,7,31) # This is the end of the plan year.

plan_years = PlanYear.where(:start_date => clone_start_date)

count = 0

feins = %w()

plan_years.each do |plan_year|
  next if feins.include?(plan_year.employer.fein) == false
  count += 1
  conflicts = plan_year.employer.plan_years.detect{ |py| py.start_date == new_start_date}
  if conflicts
    puts "#{count} - #{conflicts.employer.name} has conflicting plan year "
  else
    if plan_year.contribution_strategy.present?
      puts "#{count} - #{plan_year.employer.name}"
      contribution_strategy = plan_year.contribution_strategy
      reference_plan = contribution_strategy.reference_plan
      next_years_plan = reference_plan.renewal_plan
      new_plan_year = PlanYear.create!({
        :start_date => new_start_date,
        :end_date => new_end_date,
        :broker_id => plan_year.broker_id,
        :employer_id => plan_year.employer_id
      })
      contribution_strategy = EmployerContributions::DistrictOfColumbiaEmployer.create!({
        :plan_year_id => new_plan_year.id,
        :reference_plan_id => next_years_plan.id,
        :employee_max_percent => contribution_strategy.employee_max_percent,
        :dependent_max_percent => contribution_strategy.dependent_max_percent
      })
    end
  end
end
