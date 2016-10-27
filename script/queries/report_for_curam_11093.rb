#script to generate a report for Curam team-11093
def policy_calculator(policy)
  renewal_policy = policy.clone_for_renewal(Date.new(2017, 1, 1))
  return if renewal_policy.plan.nil?  
  pc = ::Premiums::PolicyCalculator.new
  pc.apply_calculations(renewal_policy)
  renewal_policy
end

def csr_percentage(csr_variant_id)
  return if csr_variant_id.nil?
  if csr_variant_id == "04"
    return variant = "73"
  elsif csr_variant_id == "05"
    return variant = "87"
  elsif csr_variant_id == "06"
    return variant = "94"
  elsif csr_variant_id == "02"
    return variant = "100"
  else
    return variant = ""
  end
end

report_csv =CSV.open("/Users/Varun/Desktop/reports/oct_26/report_for_curam_oct_27_no_hbx_id_list.csv", "w")

report_csv << %w(applid ic_ref firstname lastname hbxid applied_aptc csr_variant_id csr_pct coverage_type_1 policy.qhp.eg_id 2016qhp 2017crossover_renewal_qhp 2016_qhp_premium 2017_health_premium applied_aptc(dental) csr_variant_id csr_pct coverage_type_2 policy.dental.eg_id 2016_dental 2017crossover_renewal_dental 2016_dental_premium 2017_dental_premium)
begin
  csv = CSV.open('/Users/Varun/Downloads/new_rev101316/11093_no_hbx_id_list.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
  @data= csv.to_a
  @data.each do |d|
    person = Person.where({"members.ssn" => d["ssn"], "name_first" => /#{d["firstname"]}/i, "name_last" => /#{d["lastname"]}/i}).first
    # person = Person.where(:authority_member_id => d["hbxid"]).first
    begin
      if person.present? && d["subscriber"].downcase == "y"
        policies = person.policies.includes(:plan).where("enrollees.coverage_start" => {"$gt" => Date.new(2015,12,31)}).to_a
        active_health_policies = policies.select{|p| p.is_active? && p.plan.coverage_type == 'health'}
        active_health_policy = active_health_policies.sort{|x,y| y.policy_start <=> x.policy_start}.first
        active_dental_policies = policies.select{|p| p.is_active? && p.plan.coverage_type == 'dental'}
        active_dental_policy = active_dental_policies.sort{|x,y| y.policy_start <=> x.policy_start}.first
        row = [d["applid"],  d["ic_ref"], d["firstname"], d["lastname"], person.authority_member_id, ]
        if active_health_policy 
          row += [active_health_policy.applied_aptc, active_health_policy.plan.csr_variant_id, csr_percentage(active_health_policy.plan.csr_variant_id), active_health_policy.coverage_type, active_health_policy.eg_id, active_health_policy.plan.name, active_health_policy.plan.try(:renewal_plan).try(:name), active_health_policy.pre_amt_tot.to_s]
          renewal_health = policy_calculator(active_health_policy)
          row += [renewal_health.try(:pre_amt_tot)]
        end
        if active_dental_policy
          row += [active_dental_policy.applied_aptc, active_dental_policy.plan.csr_variant_id, csr_percentage(active_dental_policy.plan.csr_variant_id), active_dental_policy.plan.coverage_type, active_dental_policy.eg_id, active_dental_policy.plan.name, active_dental_policy.plan.try(:renewal_plan).try(:name), active_dental_policy.pre_amt_tot.to_s]
          renewal_dental= policy_calculator(active_dental_policy)
          row += [renewal_dental.try(:pre_amt_tot)]
        end
        report_csv << row
      end
    rescue Exception => e
      puts "Error #{e} #{e.backtrace}"
    end
  end  
rescue Exception => e
  puts "Unable to open file #{e} #{e.backtrace}"
end
