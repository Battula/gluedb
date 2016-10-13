# Finds shop policies with  individual market plans
# limitation - the market type field was only put into use in 2016, 
# so we cannot evaluate 2015 policies without that data being added

ivl_plans = Plan.where(market_type: "individual").map(&:_id)

shop_policies = Policy.where(:employer_id => {"$ne" => nil}, :plan_id => {"$in" => ivl_plans})

CSV.open("shop_policies_with_ivl_plans_#{Time.now.strftime('%m%d%Y_%H%M%S')}.csv", "w") do |csv|
  csv << ["Policy ID", "AASM State", 
          "Employer FEIN","Employer Name", 
          "Plan Name", "Plan HIOS", 
          "Subscriber Name", "Subscriber HBX ID",
          "Coverage Start"]
  shop_policies.each do |shop_policy|
    eg_id = shop_policy.eg_id
    aasm = shop_policy.aasm_state
    employer = shop_policy.employer
    fein = employer.fein
    employer_name = employer.name
    plan = shop_policy.plan
    plan_name = plan.name
    hios = plan.hios_plan_id
    subscriber_name = shop_policy.subscriber.person.full_name
    subscriber_hbx_id = shop_policy.subscriber.m_id
    effective_date = shop_policy.policy_start
    csv << [eg_id, aasm, fein, employer_name, plan_name, hios, subscriber_name, subscriber_hbx_id, effective_date]
  end
end