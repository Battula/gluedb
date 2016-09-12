require 'csv'

only_nfp = []
only_hbx = []

nfp_rows = []
hbx_rows = []

def premium_total_amount(pre_amt)
  return 0.00 if pre_amt.blank?
  pre_amt.strip.gsub("$", "").gsub(",", "").to_f
end

def match_row?(nfp_row, hbx_row)
  n_s_id = nfp_row["SubscriberID"]
  n_m_id = nfp_row["MemberID"]
#  n_eg_id = nfp_row["PolicyID"]
  n_hios_id = nfp_row["HIOSID"]
  n_ssn = nfp_row["SSN"]
  n_pre_tot = nfp_row[:pre_amt_tot]
  n_fein = nfp_row["EmployerFEIN"].strip
  h_s_id = hbx_row["Subscriber ID"]
  h_m_id = hbx_row["Member ID"]
#  h_eg_id = hbx_row["Policy ID"]
  h_hios_id = hbx_row["HIOS ID"]
  h_ssn = hbx_row["SSN"]
  n_cs = nfp_row['CoverageStart']
  n_ce = nfp_row['CoverageEnd']
  unless n_ce.blank? && n_ce == Date.parse(n_cs).next_year.prev_day.to_s(:db)
    n_ce = ""
  end
  h_cs = hbx_row['Coverage Start']
  h_ce = hbx_row['Coverage End']
  h_pre_tot = hbx_row[:pre_amt_tot]
  h_fein = hbx_row["Employer FEIN"].strip
  something = (
    (n_s_id == h_s_id) &&
    (n_m_id == h_m_id) &&
#    (n_eg_id == h_eg_id) &&
    (n_hios_id == h_hios_id) &&
#    (n_ssn == h_ssn) &&
    (n_pre_tot == h_pre_tot) &&
    (n_fein == h_fein) &&
    (n_cs == h_cs) &&
    (n_ce == h_ce)
  )
  something
end

def is_cancel_garbage?(nfp_row)
  cs = nfp_row['CoverageStart']
  ce = nfp_row['CoverageEnd']
  n_s_id = nfp_row["SubscriberID"]
  n_m_id = nfp_row["MemberID"]
  return true if (n_s_id != n_m_id)
  c_start = Date.parse(cs)
  # return true if c_start < Date.new(2014,12,31)
  return false if ce.blank?
  c_end = Date.parse(ce)
  c_end <= c_start
end

CSV.foreach("non_congressional_audit.csv", headers: true) do |row|
  h_row = row.to_hash
  h_row.merge!(:pre_amt_tot => premium_total_amount(h_row["Premium Total"]))
  hbx_rows << [h_row, row.fields]
end

CSV.foreach("NonCongressAudit.csv", headers: true, :encoding => 'windows-1251:utf-8' ) do |row|
  data = row.to_hash
  if !is_cancel_garbage?(data)
    h_row = row.to_hash
    h_row.merge!(:pre_amt_tot => premium_total_amount(h_row["PremiumTotal"]))
    nfp_rows << [h_row.to_hash, row.fields]
  end
end

CSV.open("non_con_nfp_only.csv", "w") do |csv|
  nfp_rows.each do |nfp_row|
    unless (hbx_rows.any? { |h_row| match_row?(nfp_row.first, h_row.first) })
      puts nfp_row.first.inspect
      csv << nfp_row.last
    end
  end
end

CSV.open("non_con_hbx_only.csv", "w") do |csv|
  hbx_rows.each do |hbx_row|
    unless (nfp_rows.any? { |n_row| match_row?(n_row.first, hbx_row.first) })
      csv << hbx_row.last
    end
  end
end
