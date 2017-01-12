require "rails_helper"

RSpec.describe "people/show.html.erb" do
  include Devise::TestHelpers
	let(:person) { FactoryGirl.build(:person) }
	let(:policy) { FactoryGirl.build(:policy)}
	# let(:user) { FactoryGirl.build(:user, :admin)}

	before(:each) do
		# binding.pry
		# assign(:user, user)
		# @user = user
		# sign_in @user
		# binding.pry
    	assign(:person, person)
    	person.addresses.build(kind: 'home')
    	assign(:policy, policy)
      assign(:member_documents, [])
	end

	it "should show enrollment group ID" do 
		render :template => "people/show"
	end

end
