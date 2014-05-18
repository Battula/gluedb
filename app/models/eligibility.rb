class Eligibility
  include Mongoid::Document
  include Mongoid::Timestamps

	field :date_determined, type: Date
  field :magi, type: BigDecimal, default: 0.00  # Modified Adjusted Gross Income
  field :max_aptc, type: BigDecimal, default: 0.00
  field :csr_percent, type: BigDecimal, default: 0.00

  embedded_in :household

  validates_presence_of :date_determined, :max_aptc, :csr_percent
  validate :csr_as_percent

	# Validate csr_percent value is in range 1..0
  def csr_as_percent
		errors.add(:csr_percent, "value must be between 0 and 1") unless (0 <= csr_percent && csr_percent <= 1)
  end

end
