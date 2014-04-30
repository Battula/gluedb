class ChangeVocabulary
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  ChangePerson  = Struct.new(:selected, :m_id, :name, :role) do
    def initialize(h)
      super(*h.values_at(:selected, :m_id, :name, :role))
    end

    def persisted?
      false
    end
  end  

  attr_accessor :policy_id
  attr_accessor :operation, :reason
  attr_accessor :people
  attr_accessor :policy

  def initialize(props = {})
    @policy_id = props[:policy_id]
    @policy = Policy.find(@policy_id.to_i)
    @operation = props[:operation]
    @reason = props[:reason]
    ppl_hash = props.fetch(:people_attributes) { {} }
    if ppl_hash.empty?
      @people = map_people_from_policy(@policy)
    else
      @people = ppl_hash.values.map { |person| ChangePerson.new(person) }
    end
  end

  def map_people_from_policy(enroll)
    policy.enrollees.map do |em|
      per = em.person
      ChangePerson.new({:m_id => em.m_id, :name => per.name_full, :role => em.rel_code, :selected => true})
    end
  end

  def to_cv
    members = @people.reject { |p| p.selected == "0" }
    member_ids = members.map(&:m_id)
    ser = CanonicalVocabulary::MaintenanceSerializer.new(
      @policy,
      @operation,
      @reason,
      member_ids
    )
    ser.serialize
  end

  def people_attributes=(pas)
  end

  def persisted?; false; end

  def self.operations
    [
      ["Operation Type", nil],
      ["add", "add"],
      ["audit", "audit"],
      ["cancel", "cancel"],
      ["change", "change"],
      ["terminate", "terminate"],
      ["reinstate", "reinstate"]
    ]
  end

  def self.reasons
    [
      ["Reason", nil],
      ["birth", "birth"],
      ["adoption", "adoption"],
      ["death", "death"],
      ["marriage", "marriage"],
      ["divorce", "divorce"],
      ["age_off", "age_off"],
      ["initial_enrollment", "initial_enrollment"],
      ["termination_of_benefits", "termination_of_benefits"],
      ["benefit_selection", "benefit_selection"],
      ["change_of_location", "change_of_location"],
      ["change_in_identifying_data_elements", "change_in_identifying_data_elements"],
      ["reenrollment", "reenrollment"],
      ["non_payment", "non_payment"],
      ["notification_only", "notification_only"]
    ]
  end
end
