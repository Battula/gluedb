# script to calculate the 2017 premiums for IVLR 8 Notice.
report_csv =CSV.open("/Users/Varun/Desktop/reports/nov_14/premium_report_glue.csv", "w")
report_csv << %w(family.e_case_id policy.eg_id  policy.plan.name  policy.renewal_plan.name pre_amt_tot hbx_enrollment.policy.policy_start  policy.aasm_state policy.plan.coverage_type policy.plan.metal_level person.authority_member_id person.name_full person.mailing_address person.authority_member.is_incarcerated person.authority_member.citizen_status  person.authority_member.is_state_resident is_dependent  is_responsible_party?)
begin
  csv = CSV.open('/Users/Varun/Desktop/reports/nov_14/11455_export_glue_plan_family_no_dependents.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
  @data= csv.to_a
  @data.each do |d|
    policy = Policy.where(:eg_id => d["policy.eg_id"]).first
    begin
    renewal_policy = policy.clone_for_renewal(Date.new(2017, 1, 1))
    pc = ::Premiums::PolicyCalculator.new
    pc.apply_calculations(renewal_policy) unless renewal_policy.plan.nil?
    rescue Exception => e
      puts "Unable to find premiums for #{policy.eg_id} #{e} #{e.backtrace}"
    end
    report_csv.add_row([d["family.e_case_id"],d["policy.eg_id"],d["policy.plan.name"],d["policy.renewal_plan.name"],renewal_policy.try(:pre_amt_tot).try(:to_s),d["hbx_enrollment.policy.policy_start"],d["policy.aasm_state"],d["policy.plan.coverage_type"],d["policy.plan.metal_level"],d["person.authority_member_id"], d["person.name_full"], d["person.mailing_address"], d["person.authority_member.is_incarcerated"],d["person.authority_member.citizen_status"],d["person.authority_member.is_state_resident"],d["is_dependent"],d["is_responsible_party?"]])
  end
rescue Exception => e
  puts "Unable to open file #{e} #{e.backtrace}"
end
