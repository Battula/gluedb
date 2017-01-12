require 'rails_helper'

describe DashboardsController, :dbclean => :after_each do
  login_user

  describe 'GET index' do

    it "should have a table of transactions" do
      allow(Protocols::X12::TransactionSetEnrollment).to receive(:last).and_return(double(updated_at: Time.now))
      get :index
      expect(assigns( :transactions )).not_to be_nil
    end
  end
end
