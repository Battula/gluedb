require 'csv'

namespace :migrations do 
  namespace :update_aptc_amounts do 
    filename = ''
    CSV.foreach(filename, headers: true) do |row|
      policy = Policy.where(eg_id: row["enrollment_group_id"]).first
      policy.applied_aptc = row["CURAM 2017 APTC"].to_d
      policy.save!
      policy.tot_res_amt = policy.pre_amt_tot - policy.applied_aptc
      policy.save!
    end
  end
end