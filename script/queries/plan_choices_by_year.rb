# Returns a report of raw plan counts by year and plan, broken down into SHOP and IVL counts. 
require 'csv'

plans_2014 = Plan.where(year: 2014)

plans_2015 = Plan.where(year: 2015)

plans_2016 = Plan.where(year: 2016)


def return_shop_policy_count(plan)
	policies = Policy.where(:aasm_state => {"$ne" => "canceled"},
							:plan_id => {"$eq" => plan._id},
							:employer_id => {"$ne" => nil})
	return policies.size.to_d
end

def return_ivl_policy_count(plan)
	policies = Policy.where(:aasm_state => {"$ne" => "canceled"},
						:plan_id => {"$eq" => plan._id},
						:employer_id => {"$eq" => nil})
	return policies.size.to_d
end

CSV.open("plan_choices_by_year.csv", "w") do |csv|
	csv << ["Plan Name", "Plan HIOS ID", "Plan Year", "Carrier", "SHOP Policy Count", "IVL Policy Count",
			"Renewal Plan Name", "Renewal Plan HIOS ID", "Renewal Plan Year", "Renewal Plan Carrier", "Renewal SHOP Policy Count", "Renewal IVL Policy Count"]
	plans_2014.each do |plan|
		plan_name = plan.name
		plan_hios_id = plan.hios_plan_id
		plan_year = plan.year
		plan_carrier = plan.carrier.name
		plan_shop_policy_count = return_shop_policy_count(plan)
		plan_ivl_policy_count = return_ivl_policy_count(plan)
		renewal_plan = plan.renewal_plan
		unless renewal_plan == nil
			renewal_plan_name = renewal_plan.name
			renewal_plan_hios_id = renewal_plan.hios_plan_id
			renewal_plan_year = renewal_plan.year
			renewal_plan_carrier = renewal_plan.carrier.name
			renewal_plan_shop_policy_count = return_shop_policy_count(renewal_plan)
			renewal_plan_ivl_policy_count = return_ivl_policy_count(renewal_plan)
			csv << [plan_name,plan_hios_id,plan_year,plan_carrier,
					plan_shop_policy_count,plan_ivl_policy_count,
					renewal_plan_name,renewal_plan_hios_id,renewal_plan_year,renewal_plan_carrier,
					renewal_plan_shop_policy_count,renewal_plan_ivl_policy_count]
		else
			csv << [plan_name,plan_hios_id,plan_year,plan_shop_policy_count,plan_ivl_policy_count,"No Renewal Plan Found"]
		end
	end
	plans_2015.each do |plan|
		plan_name = plan.name
		plan_hios_id = plan.hios_plan_id
		plan_year = plan.year
		plan_carrier = plan.carrier.name
		plan_shop_policy_count = return_shop_policy_count(plan)
		plan_ivl_policy_count = return_ivl_policy_count(plan)
		renewal_plan = plan.renewal_plan
		unless renewal_plan == nil
			renewal_plan_name = renewal_plan.name
			renewal_plan_hios_id = renewal_plan.hios_plan_id
			renewal_plan_year = renewal_plan.year
			renewal_plan_carrier = renewal_plan.carrier.name
			renewal_plan_shop_policy_count = return_shop_policy_count(renewal_plan)
			renewal_plan_ivl_policy_count = return_ivl_policy_count(renewal_plan)
			csv << [plan_name,plan_hios_id,plan_year,plan_carrier,
					plan_shop_policy_count,plan_ivl_policy_count,
					renewal_plan_name,renewal_plan_hios_id,renewal_plan_year,renewal_plan_carrier,
					renewal_plan_shop_policy_count,renewal_plan_ivl_policy_count]
		else
			csv << [plan_name,plan_hios_id,plan_year,plan_shop_policy_count,plan_ivl_policy_count,"No Renewal Plan Found"]
		end
	end
	plans_2016.each do |plan|
		plan_name = plan.name
		plan_hios_id = plan.hios_plan_id
		plan_year = plan.year
		plan_carrier = plan.carrier.name
		plan_shop_policy_count = return_shop_policy_count(plan)
		plan_ivl_policy_count = return_ivl_policy_count(plan)
		csv << [plan_name,plan_hios_id,plan_year,plan_carrier,plan_shop_policy_count,plan_ivl_policy_count,"N/A"]
	end
end