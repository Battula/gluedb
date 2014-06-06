class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Paranoia
  
  extend Mongorder

  field :name, type: String
  field :abbrev, as: :abbreviation, type: String
  field :hbx_plan_id, type: String  # internal ID for plan
  field :hios_plan_id, type: String
  field :coverage_type, type: String
  field :metal_level, type: String
  field :market_type, type: String 
  field :ehb, as: :ehb_max_as_percent, type: BigDecimal, default: 0.0

  index({ hbx_plan_id: 1 }, { unique: true, name: "exchange_plan_id_index" })
	index({ hios_plan_id: 1 }, { unique: false, name: "hios_plan_id_index" })
  index({ coverage_type: 1 })
  index({ metal_level: 1 })
  index({ market_type: 1 })

  validates_inclusion_of :coverage_type, in: ["health", "dental"]
#  validates_inclusion_of :market_type, in: ["individual", "shop"]


	belongs_to :carrier, index: true
  has_many :policies, :inverse_of => :plan
  has_and_belongs_to_many :employers
  embeds_many :premium_tables

  before_save :invalidate_find_cache

  def invalidate_find_cache
    Rails.cache.delete("Plan/find/hios_plan_id.#{self.hios_plan_id}")
    true
  end

  def self.find_by_hios_id(h_id)
    Rails.cache.fetch("Plan/find/hios_plan_id.#{h_id}") do
      Plan.where(
        :hios_plan_id => h_id
      ).first
    end
  end

  # Provide premium rate given the rate schedule, date coverage will start, and applicant age when coverage starts
  def rate(rate_period_date, benefit_begin_date, birth_date)
    age = Ager.new(birth_date).age_as_of(benefit_begin_date)
    premiums = Collections::Premiums.new(self.premium_tables).for_date(rate_period_date).for_age(age)
    premiums.to_a.first.amount
  end

  def self.default_search_order
    [
      ["name", 1],
    ]
  end

  def self.search_hash(s_str)
    Hash.new
  end
end
