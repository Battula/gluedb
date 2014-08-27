require 'csv'

class ChangeMemberAddressRequest
  class CsvRequest
    def initialize(csv_row)
      @row = csv_row
    end

    def to_hash
      @row.to_hash
    end

    def to_a
      @row.fields
    end
  end


  def self.many_from_csv(spreadsheet)
    requests = Array.new

    CSV.foreach(spreadsheet, headers: true, header_converters: :symbol, converters: :all, skip_blanks: true) do |row|
      requests << CsvRequest.new(row)
    end
    requests
  end
end