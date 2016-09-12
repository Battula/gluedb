require 'csv'
require 'pry'

CSV.foreach("plan_hios_export.csv") do |row|
	hios_ids = row.to_a
	plan_2015 = Plan.where(:hios_plan_id => {"$eq" => hios_ids[0]}, :year => 2015).first
	plan_2016 = Plan.where(:hios_plan_id => {"$eq" => hios_ids[1]}, :year => 2016).first
	plan_2015.renewal_plan = plan_2016
	plan_2015.save!
end