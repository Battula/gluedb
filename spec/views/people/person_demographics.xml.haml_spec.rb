
require "rails_helper"

shared_examples_for "a person_demographics" do
  it "has birth date" do
    expected_node = subject.at_xpath("//person_demographics/birth_date")
    expect(expected_node.content).to eq  simple_date_for(person.authority_member.dob)
  end
end

describe "people/_person_demographics.xml", :dbclean => :after_each do

  let(:render_result) {
    render :partial => "people/person_demographics", :formats => [:xml], :object => person
    rendered
  }

  subject{
    Nokogiri::XML(render_result)
  }

  describe "Given:
                - Have an bithdate with no default sex and ssn" do

    let(:person) { FactoryGirl.create(:person) }
    before do
      person.authority_member = person.members.first.hbx_member_id
      person.authority_member.dob = "some birth date"
      person.authority_member.ssn=nil
      person.authority_member.unset(:gender)

    end
    it_should_behave_like "a person_demographics"
    it "it should have no default sex" do
      expected_node = subject.at_xpath("//person_demographics/sex")
      expect(expected_node.content).to eq "urn:openhbx:terms:v1:gender#unknown"
    end
    it "it should have ssn" do
      expected_node = subject.at_xpath("//person_demographics/ssn")
      expect(expected_node).to eq nil
    end
    end

  describe "Given:
                - Have an bithdate and default sex female" do
    let(:person) { FactoryGirl.create(:person) }
    before do
      person.authority_member = person.members.first.hbx_member_id
      person.authority_member.dob = "some birth date"

    end
    it_should_behave_like "a person_demographics"
    it "it should be female" do
      expected_node = subject.at_xpath("//person_demographics/sex")
      expect(expected_node.content).to eq "urn:openhbx:terms:v1:gender##{person.authority_member.gender}"
    end
    it "it should have ssn" do
      expected_node = subject.at_xpath("//person_demographics/ssn")
      expect(expected_node.content).to eq person.authority_member.ssn
    end
  end

end
