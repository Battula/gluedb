require 'rails_helper'

describe 'matching a person', :dbclean => :after_each do
  let(:person) { Person.new(name_last: last_name, name_first: first_name, members: members, emails: emails) }
  let(:member) { Member.new(ssn: member_ssn, gender: 'male', dob: dob, hbx_member_id: member_id) }
  let(:members) { [member] }
  let(:member_ssn) {'123456789' }
  let(:last_name) { 'Dirt' }
  let(:first_name) { 'Joe' }
  let(:member_id) { '123445554564577' }
  let(:dob) { Date.today.prev_year }
  let(:emails) { [email] }
  let(:email) { Email.new(email_type: 'home', email_address: "bigsacklunch@example.com") }

  before(:each) do
    person.save!
  end
  context 'with a member id' do
    it 'finds person with member id' do
      expect(Queries::PersonMatch.find({member_id: member_id})).to eq person
    end
  end
  context "with a matching ssn" do
    it 'finds person with the same ssn' do
      expect(Queries::PersonMatch.find({ssn: member_ssn })).to eq person
    end

    it "should not find the person if the last name does not match" do
      expect(Queries::PersonMatch.find({ssn: member_ssn, name_last: "lkasjdfkljasdf"})).to eq nil
    end

    context "when multiple people have the same ssn" do
      let(:other_person) { Person.new(name_last: other_last_name, name_first: other_first_name, members: members, emails: emails) }
      let(:other_member) { Member.new(ssn: member_ssn, gender: 'male', dob: Date.today.prev_year) }
      let(:other_last_name) { "Steve" }
      let(:other_first_name) { "Matt"}
      before(:each) do
        other_person.save!
      end

      it "should return nothing when no last name is provided" do
        expect(Queries::PersonMatch.find({ssn: member_ssn})).to eq nil
      end

      it "should only match the one with the matching last name if more than one has that ssn" do
        expect(Queries::PersonMatch.find({ssn: member_ssn, name_last: last_name})).to eq person
      end

      context "when there is no difference in last name" do
        let(:other_last_name) { last_name }

        it "should return nothing" do
          expect(Queries::PersonMatch.find({ssn: member_ssn, name_last: last_name})).to eq nil
        end

        it "should return the right person if only one matches first name, last name, and dob" do
          expect(Queries::PersonMatch.find({ssn: member_ssn, name_last: last_name, name_first: first_name, dob: dob})).to eq person
        end

        context "with all names and dobs the same" do
          let(:other_first_name) { first_name }
          it "should return nothing" do
            expect(Queries::PersonMatch.find({ssn: member_ssn, name_last: last_name, name_first: first_name, dob: dob})).to eq nil
          end
        end

      end
    end
  end

  context "with a matching first name, last name, and dob" do

    it "should find the person" do
      expect(Queries::PersonMatch.find({ssn: "2342314123dsafadf", name_first: first_name, name_last: last_name, dob: dob})).to eq person
    end
  end

  context 'when person has no members' do
    let(:members) { [] }
    it 'finds by name and email' do
      expect(Queries::PersonMatch.find({ssn: "not in glue", name_first: first_name, name_last: last_name, dob: Date.today.prev_year.prev_year, email: email.email_address})).to eq person
    end
  end
end
