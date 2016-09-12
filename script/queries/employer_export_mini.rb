## This script takes a list of FEINs as input and then returns the corresponding HBX IDs. This is useful for loading into B2B table.
require 'csv'

employer_feins = %w()

employers = Employer.where(:fein => {"$in" => employer_feins})



CSV.open("employer_export_mini.csv", "w") do |csv|
  csv << ["FEIN", "HBX ID"]
  employers.each do |employer|
    fein = employer.try(:fein)
    hbx_id = employer.try(:hbx_id)
    csv << [fein, hbx_id]
  end
end