require "rails_helper"

RSpec.describe "people/show.html.erb" do
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
	end

	it "should show enrollment group ID" do 
		render :template => "people/show.html.erb"
		expect(rendered).to have_content p.eg_id
	end

end