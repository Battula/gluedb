require 'csv'

class MultipleAptcImporter

  attr_accessor :policies

  # file_path - path to the csv file.
  # schema - Policy ID, IssuerAPTCAmount,	IssueSubsidyStartDate,	IssuerSubsidyEndDate
  # sample row - 11912,	141,	1/1/14,	2/28/14
  def initialize(file_path)
    @file_path = file_path
    @policies = []
  end

  def apply_multiple_aptc
    @logger = Logger.new("#{Rails.root}/log/multiple_aptc_importer_#{Time.now.to_s.gsub(' ', '')}.log")

    CSV.foreach(@file_path, :headers => :first_row) do |row|
      begin
        policy = Policy.find(row[0])
        aptc_credit = policy.aptc_credits.build({start_on: Date.strptime(row[2], "%m/%d/%Y"),
                                   end_on: Date.strptime(row[3], "%m/%d/%Y"),
                                   aptc: row[1]})
        aptc_credit.save!
        @policies << policy
        @logger.info "Processed Policy:#{policy.id} with APTC: " + policy.aptc_credits.inspect
      rescue Exception => e
        @logger.error "Could not process #{row[0]} " + e.message
      end
    end
  end
end

aptc_importer = MultipleAptcImporter.new('1095_KP_2016_MidYear_APTC_ScriptUpdates.csv')
aptc_importer.apply_multiple_aptc