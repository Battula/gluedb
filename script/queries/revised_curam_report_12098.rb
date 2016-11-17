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

report_csv =CSV.open("/Users/Varun/Desktop/reports/nov_17/revised_report_12098_#{DateTime.now.to_s}.csv", "w")

report_csv << %w(APPLICATIONREF ICACASEREF  FIRSTNAME LASTNAME  hbxid APTC  csr_variant_id  csr_pct coverage_type_1 policy.qhp.eg_id  CODE  LASTHEALTHPLAN  NEXTHEALTHPLAN  2016_qhp_premium  NEXTHEALTHPLANPREMIUM applied_aptc(dental)  csr_variant_id  csr_pct coverage_type_2 policy.dental.eg_id LASTDENTALPLAN  NEXTDENTALPLAN  2016_dental_premium 2017_dental_premium actual_health_aptc actual_health_csr_id actual_health_csr_pc actual_health_premium actual_dental_aptc actual_dental_premium)
begin
  csv = CSV.open('/Users/Varun/Desktop/reports/nov_17/report_for_curam_oct_26_final_report_0152PM.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
  @data= csv.to_a
  @data.each do |d|
    person = Person.where(:authority_member_id => d["hbxid"]).first
    begin
      if person.present?
        policies = person.policies.includes(:plan).where("enrollees.coverage_start" => {"$gt" => Date.new(2016,12,31)}).to_a
        health_policies = policies.select{|p| p.plan.coverage_type == 'health'}
        health_policy = health_policies.sort{|x,y| y.policy_start <=> x.policy_start}.first
        dental_policies = policies.select{|p| p.plan.coverage_type == 'dental'}
        dental_policy = dental_policies.sort{|x,y| y.policy_start <=> x.policy_start}.first
        row = [d["APPLICATIONREF"], d["ICACASEREF"],  d["FIRSTNAME"], d["LASTNAME"], d["hbxid"], d["APTC"], d["csr_variant_id"], d["csr_pct"], d["coverage_type_1"], d["policy.qhp.eg_id"], d["CODE"], d["LASTHEALTHPLAN"], d["NEXTHEALTHPLAN"], d["2016_qhp_premium"], d["NEXTHEALTHPLANPREMIUM"], d["applied_aptc(dental)"], d["csr_variant_id"], d["csr_pct"], d["coverage_type_2"], d["policy.dental.eg_id"], d["LASTDENTALPLAN"], d["NEXTDENTALPLAN"], d["2016_dental_premium"], d["2017_dental_premium"]]
        if health_policy 
          row += [health_policy.applied_aptc, health_policy.plan.csr_variant_id, csr_percentage(health_policy.plan.csr_variant_id), health_policy.pre_amt_tot.to_s]
        end
        if dental_policy
          row += [dental_policy.applied_aptc, dental_policy.pre_amt_tot.to_s]          

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