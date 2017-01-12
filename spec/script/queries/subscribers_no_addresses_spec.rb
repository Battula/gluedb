require 'rails_helper'
require File.join(Rails.root, "script", "queries", "subscribers_no_addresses")

describe 'find_previous_home_addresses', :dbclean => :after_each do
	it 'should return an empty array if the person has not been updated' do
		person = FactoryGirl.create :person
		expect(find_previous_home_addresses(person)).to eq []
	end

	it 'should return an array of strings if the person has been updated' do
		person = FactoryGirl.create :person
    person.name_first = "James"
    person.save!
    person.remove_address_of('home')
    person.save!
    person = Person.where(name_first: "James").first
		expect(find_previous_home_addresses(person).map(&:class).uniq.first.to_s).to eq 'String'
	end
end
