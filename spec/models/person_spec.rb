require 'spec_helper'

describe Person do
  describe "validate associations" do
	  it { should belong_to :household }
	  it { should embed_many :members }
	  it { should embed_many :addresses }
	  it { should embed_many :emails }
	  it { should embed_many :phones }
	  it { should embed_many :responsible_parties }

	  it { should accept_nested_attributes_for(:addresses) }
  end

 
  describe "instantiates object." do
		it "sets and gets all basic model fields" do
      psn = Person.new(
        name_pfx: "Mr",
        name_first: "John", 
        name_middle: "Jacob",
        name_last: "Jingle-Himer",
        name_sfx: "Sr"
      )
      psn.name_pfx.should == "Mr"
      psn.name_first.should == "John"
      psn.name_middle.should == "Jacob"
      psn.name_last.should == "Jingle-Himer"
      psn.name_sfx.should == "Sr"
    end
  end

  describe "manages embedded contact attributes" do
    it "sets and gets address attributes" do
      psn = Person.new
      psn.addresses << Address.new(
        address_type: "work",
        address_1: "101 Main St",
        address_2: "Apt 777",
        city: "Washington",
        state: "DC",
        zip: "20001"
      )
    end

    it "sets and gets email attributes" do
      psn = Person.new
      psn.emails << Email.new(
        email_type: "work",
        email_address: "john.Jingle-Himer@example.com"
      )
    end

    it "sets and gets phone attributes" do
      psn = Person.new
      psn.phones << Phone.new(
        phone_type: "mobile",
        phone_number: "+1-202-555-1212"
      )
    end
  end

  describe "manages member roles" do

    # This is mainly because I hate instance variables.
    let(:mbr_id) { "1234"}

    before :each do
      @date1 = Time.new(1980,10,23,0,0,0)
      @mbr_ssn = 789999999
      @mbr_sex = "female"
      @mbr_tobacco = "unknown"
      @mbr_language = "en"
    end
    it "appends multiple members" do
      psn = Person.new
      psn.members << Member.new(
        hbx_member_id: mbr_id, 
        dob: @date1,
        ssn: @mbr_ssn,
        gender: @mbr_sex,
        tobacco_use_code: @mbr_tobacco,
        lui: @mbr_language
      )
      psn.members << Member.new(
        hbx_member_id: (mbr_id.to_i + 100).to_s, 
        dob: @date1,
        ssn: @mbr_ssn,
        gender: @mbr_sex,
        tobacco_use_code: @mbr_tobacco,
        lui: @mbr_language
      )
      m = psn.members.first
      m.hbx_member_id.should == mbr_id
      m.dob.strftime("%m/%d/%Y").should == @date1.strftime("%m/%d/%Y")
      m.gender.should == @mbr_sex
      m.tobacco_use_code.should == @mbr_tobacco
      m.lui.should == @mbr_language

    end
  end

  describe "manages enrollment roles" do
    # it "Sets MemberEnrollment attributes" do
    # 	psn = Person.first
    # 	psn.member_enrollments << MemberEnrollment.new(
    # 			enrollment_id: 343434,
    # 			subscriber_id: 4545, 
    # 			disability_status: false,
    # 			carrier_id: 5656,
    # 			benefit_status_code: "active",
    # 			relationship_status_code: "self")
    # 	psn.save!
    # end
  end


  describe "manages responsible party roles" do
  end


  describe "tracks changes" do
    it "in embedded models" do

      p =	Person.create!({
        name_pfx: "Dr",
        name_first: "Leonard", 
        name_middle: "H",
        name_last: "McCoy",
        members: [
          Member.new({gender: "female", ssn: "564781254", dob: "19890312"})
        ],
        addresses: [
          Address.new({address_type: "home", address_1: "110 Main St", city: "Washington", state: "DC", zip: "200001"}),
          Address.new({address_type: "work", address_1: "222 Park Ave", city: "Washington", state: "DC", zip: "200002"})
        ]
      })

      q = Person.find p
      q.name_first = "Bones"
      q.members.first.gender = "male"
      q.addresses.first.address_type = "billing"
      q.addresses.last.state = "CA"

      delta = q.changes_with_embedded
      expect(delta[:person].first[:name_first][:from]).to eq("Leonard")
      expect(delta[:person].first[:name_first][:to]).to eq("Bones")

      expect(delta[:addresses].first[:address_type][:to]).to eq("billing")
      expect(delta[:addresses].last[:state][:to]).to eq("CA")

      expect(delta[:members].first[:gender][:to]).to eq("male")
    end
  end

  describe 'authority member id assignment' do
    let(:person) { Person.new }
    context 'one member' do
      let(:member) { Member.new(hbx_member_id: 1) }
      its 'authority member id is the member hbx id' do
        person.members << member
        person.assign_authority_member_id
        expect(person.authority_member_id).to eq member.hbx_member_id
      end
    end 
    context 'more than one member' do
      its 'authority member id is nil' do
        2.times { |i| person.members << Member.new(hbx_member_id: i) }
        person.assign_authority_member_id
        expect(person.authority_member_id).to be_nil
      end
    end
  end

  describe 'being searched for members' do
    let(:member_ids) { ["a", "b" "c" ] }

    let(:query) { PersonMemberQuery.new(member_ids) }

    it "should search for the specified members" do
      expect(Person).to receive(:where).with(query.query)
      Person.find_for_members(member_ids)
    end
  end

  describe '#full_name' do
    let(:person) { Person.new(name_pfx: 'Mr', name_first: 'Joe', name_middle: 'X', name_last: 'Dirt', name_sfx: 'Jr') }
    it 'returns persons full name as string' do
      expect(person.full_name).to eq 'Mr Joe X Dirt Jr'
    end
  end
end
