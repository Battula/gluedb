require 'rails_helper'

describe EdiTransactionSetsController, :dbclean => :after_each do
  login_user

  describe 'GET errors' do
     it "renders errors" do
      get :errors
      expect(response).to have_http_status(:success)
      expect(response).to render_template :errors
    end
  end
end
