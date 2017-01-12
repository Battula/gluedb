require 'rails_helper'

describe Enrollee, :dbclean => :after_each do
  describe '#member' do
    let(:enrollee) { Enrollee.new(relationship_status_code: 'self', employment_status_code: 'active', benefit_status_code: 'active') }
    let(:id_to_lookup) { '666' }
    let(:different_id) { '777' }
    let(:person) { Person.new(name_first: 'Joe', name_last: 'Dirt') }
    let(:member) { Member.new(gender: 'male') }

    context 'no members with matching hbx id' do
      before do
        enrollee.m_id = different_id
        member.hbx_member_id = id_to_lookup
        person.members << member
        person.save!
      end
      it 'returns nil' do 
        expect(enrollee.member).to eq nil
      end
    end

    context 'member exists with matching hbx id' do
      before do
        enrollee.m_id = id_to_lookup
        member.hbx_member_id = id_to_lookup
        person.members << member
        person.save!
      end
      it 'returns the member' do 
        expect(enrollee.member).to eq member
      end
    end
  end

  describe '#person' do
    let(:person) { Person.new(name_first: 'Joe', name_last: 'Dirt') }
    let(:member) { Member.new(gender: 'male') }
    let(:lookup_id) { '666' }
    let(:different_id) { '777'}
    let(:enrollee) { Enrollee.new(relationship_status_code: 'self', employment_status_code: 'active', benefit_status_code: 'active') }

    context 'no person has members with the hbx id' do
      before do
        enrollee.m_id = lookup_id
        member.hbx_member_id = different_id
        person.members << member
        person.save!
      end

      it 'returns nil' do
        expect(enrollee.person).to eq nil
      end
    end

    context 'person has members with the hbx id' do
      before do
        enrollee.m_id = lookup_id
        member.hbx_member_id = lookup_id
        person.members << member
        person.save!
      end
      it 'returns the person' do
        expect(enrollee.person).to eq person
      end
    end
  end

  context 'when coverage end date is present' do
    let(:enrollee) { Enrollee.new(coverage_end: Date.today) }
    it 'coverage has ended' do
      expect(enrollee.coverage_ended?).to be_true
    end
  end
end
