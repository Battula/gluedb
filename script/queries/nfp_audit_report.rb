require 'csv'

headers = [
  "Subscriber ID",
  "Member ID",
  "Relationship",
  "Policy ID",
  "First Name",
  "Middle Name",
  "Last Name",
  "DOB",
  "SSN",
  "Plan Name",
  "HIOS ID",
  "Carrier Name",
  "Premium Amount",
  "Premium Total",
  "Policy Employer Contribution",
  "Coverage Start",
  "Coverage End",
  "Employer FEIN",
  "Employer Name"
]

congress_feins = []

emp_ids = Employer.where(:fein => { "$in" => congress_feins }).map(&:id)

pols = Policy.where({
    :enrollees => {"$elemMatch" => {
          :rel_code => "self",
          :coverage_start => {"$gt" => Date.new(2014,12,31)}
    }}, :employer_id => { "$in" => emp_ids } })

Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)
Caches::MongoidCache.allocate(Employer)

def format_date(date)
  return "" if date.blank?
  date.strftime("%Y-%m-%d")
end

CSV.open("congressional_audit.csv", "w") do |csv|
  csv << headers
  pols.each do |pol|
    if !pol.canceled?
      sub = pol.subscriber
      end_date = Date.new(2015,12,31)
      if sub.coverage_start.year == 2015 and sub.coverage_end == nil
        sub.coverage_end = end_date
      end
      s_person = pol.subscriber.person
      s_am = s_person.authority_member
      s_id = s_person.authority_member.hbx_member_id
      plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) { pol.plan }
      carrier = Caches::MongoidCache.lookup(Carrier, plan.carrier_id) { plan.carrier }
      emp = Caches::MongoidCache.lookup(Employer, pol.employer_id) { pol.employer }
#      pol.enrollees.each do |en|
#        if !en.canceled?
#          per = en.person
#          mem = per.authority_member
          csv << [
            s_id,
            s_id,
            sub.rel_code,
            pol.eg_id,
            s_person.name_first,
            s_person.name_middle,
            s_person.name_last,
            s_am.dob,
            s_am.ssn,
            plan.name,
            plan.hios_plan_id,
            carrier.name,
            sub.pre_amt,
            pol.pre_amt_tot,
            pol.tot_emp_res_amt,
            format_date(sub.coverage_start),
            format_date(sub.coverage_end),
            emp.fein,
            emp.name
          ]
#        end
#      end
    end
  end
end
