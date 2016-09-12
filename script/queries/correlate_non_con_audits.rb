require 'csv'

hbx_records = []
nfp_records = []

CSV.foreach("non_con_nfp_only.csv") do |row|
  nfp_records << (row + ["NFP"])
end

CSV.foreach("non_con_hbx_only.csv") do |row|
  hbx_records << (row + ["HBX"])
end

all_groups = (nfp_records + hbx_records).group_by { |r| r[8] }
mismatches = all_groups.values.select { |ag| ag.length > 1 }
rest = all_groups.values.select { |ag| ag.length < 2 }

rest_nfp = rest.select { |ag| ag.last.last == "NFP" }
rest_hbx = rest.select { |ag| ag.last.last == "HBX" }

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("audit_issues_non_con#{timestamp}.csv", "w") do |csv|
  csv << ["Multiple Policies"]

  mismatches.each do |v|
    v.sort_by { |v| v.last }.each do |row|
      csv << row
    end
    csv << []
  end

  csv << []
  csv << []
  csv << ["Single Policies - HBX Only", "These individuals have only one policy for 2015, and that policy is only with the HBX"]
  rest_hbx.each do |v|
    v.each do |row|
      csv << row
    end
  end

  csv << []
  csv << []
  csv << ["Single Policies - NFP Only", "These individuals have only one policy for 2015, and that policy is only with NFP."]
  rest_nfp.each do |v|
    v.each do |row|
      csv << row
    end
  end
end
