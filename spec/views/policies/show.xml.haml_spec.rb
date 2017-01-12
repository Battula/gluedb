require "rails_helper"

describe "policies.show.xml", :dbclean => :after_each do
  let(:policy) { FactoryGirl.create(:policy) }
  let(:subscriber) { FactoryGirl.create(:person) }
  let(:dependant) { FactoryGirl.create(:person) }
  let(:sub_hbx_id) { policy.enrollees.first.m_id }
  let(:dep_hbx_id) { policy.enrollees.last.m_id }

  let(:render_result) {
    render :template => "policies/show", :formats => [:xml]
  }

  before do
    subscriber.members.first.update_attributes(hbx_member_id: sub_hbx_id)
    dependant.members.first.update_attributes(hbx_member_id: dep_hbx_id)
    subscriber.update_attributes(authority_member_id: sub_hbx_id)
    dependant.update_attributes(authority_member_id: dep_hbx_id)
    assign(:policy, policy)
  end

  it "should not failsauce" do
    expect(render_result).to have_content policy.eg_id
  end
end
