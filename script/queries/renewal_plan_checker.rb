# Returns all 2015 and 2016 plans and their renewal plans. Useful for catching plan mapping discrepancies.
require 'csv'

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("renewal_plans_all_after_update_#{timestamp}.csv","w") do |csv|
	csv << ["Plan Name", "Plan Year", "Plan HIOS ID", "Renewal Plan Name", "Renewal Plan Year", "Renewal Plan HIOS ID", "Plan ID", "Renewal Plan ID", "Plan Created", "Plan EHB"]
	Plan.where(:year => {"$gte" => 2014}).to_a.each do |plan|
		plan_name = plan.try(:name)
		plan_year = plan.try(:year)
		plan_hios = plan.try(:hios_plan_id)
		plan_ehb = plan.try(:ehb)
		if plan.renewal_plan_id.present?
			renewal_name = plan.renewal_plan.try(:name)
			renewal_year = plan.renewal_plan.try(:year)
			renewal_hios = plan.renewal_plan.try(:hios_plan_id)
		else
			renewal_name = "NO_RENEWAL_PLAN"
			renewal_year = "NO_RENEWAL_PLAN"
			renewal_hios = "NO_RENEWAL_PLAN" 
		end
		plan_id = plan._id
		renewal_id = plan.renewal_plan_id
		created_at = plan.created_at
	csv << [plan_name, plan_year, plan_hios, renewal_name, renewal_year, renewal_hios, plan_id, renewal_id, created_at, plan_ehb]
	end
end