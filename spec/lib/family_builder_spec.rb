require 'rails_helper'
require Rails.root.join('lib', 'import_families')

describe FamilyBuilder, :dbclean => :after_each do

  let(:person_mapper) {
    double();
  }

  let(:member) {
    Member.new({:dob => "", :death_date => "", :ssn => "", :gender => "", :ethnicity => "", :race => "", :marital_status => ""})
  }

  let(:person) {
    Person.create({:id => "222", :members => [member]})
  }

  let(:family_member) {
    {is_primary_applicant: "true", person: person}
  }

  before(:each) {
    @person = Person.create!({name_first: "cool", :name_last => "cool2", :members => [Member.new({:dob => "", :death_date => "", :ssn => "", :gender => "male", :ethnicity => "", :race => "", :marital_status => ""})]})
    @family_member_hash = {is_primary_applicant: "true", family_member_id: "12333", person: @person}
    @person_mapper = ImportFamilies::PersonMapper.new
    @params = {e_case_id: '12345', submitted_at: DateTime.now, :tax_households=>[], :financial_statements=>[], :family_members => [@family_member_hash]}
    @family_builder = FamilyBuilder.new(@params, @person_mapper)
    @family = @family_builder.family
    @policy = Policy.new()
  }

  context "initial state" do
    it "builds a valid family object" do
      expect(@family.class.name).to eq('Family')
      expect(@family.valid?).to be_true
    end

    it "should not have a irs_group" do
      expect(@family.irs_groups.length).to eq(0)
    end

    it "adds a household" do
      expect(@family_builder.family.households.length).to eq(1)
    end
  end

  it "adds a family_member" do
    @family_builder.add_family_member(@family_member_hash)
    expect(@family_builder.family.family_members.length).to eq(1)
  end


  context "family is built" do
    it "adds a coverage_household" do
      @family_builder.add_family_member(@family_member_hash)
      @family_builder.build
      expect(@family_builder.family.households.flat_map(&:coverage_households).length).to eq(1)
    end
  end

  it "saves successfully" do
    expect(@family.save!).to eq(true)
  end

end
