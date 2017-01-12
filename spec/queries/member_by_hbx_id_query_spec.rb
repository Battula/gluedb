require 'spec_helper'

describe Queries::MemberByHbxIdQuery, :dbclean => :after_each do
  let(:existing_member) { Member.new(gender: 'male') }
  let(:lookup_id) { '666' }
  let(:different_id) { '777' }
  let(:person) { Person.new(name_first: 'Joe', name_last: 'Dirt') }

  let(:query) { Queries::MemberByHbxIdQuery.new(lookup_id) }

  context 'no person has a member with the id' do
    before { person.save! }
    it 'returns nil' do
      expect(query.execute).to eq nil
    end
  end

  context 'no matching existing member' do
    before do
      existing_member.hbx_member_id = different_id
      person.members << existing_member
      person.save!
    end
    it 'returns nil' do
      expect(query.execute).to eq nil
    end
  end

  context 'matching existing member' do
    before do
      existing_member.hbx_member_id = lookup_id
      person.members << existing_member
      person.save!
    end
    it 'returns nil' do
      expect(query.execute).to eq existing_member
    end
  end
end
