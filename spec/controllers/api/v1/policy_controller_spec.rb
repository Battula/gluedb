require 'rails_helper'

describe Api::V1::PoliciesController, :dbclean => :after_each do
  login_user

  describe 'GET show' do
    let(:policy) { create :policy }
    before { get :show, id: policy.id, format: 'xml' }

    it 'finds and assign policy for view' do
      expect(assigns(:policy)).to eq policy
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end

  describe 'GET index' do
    let(:policies) { [ create(:policy) ] }
    before { get :index, format: 'xml' }

    it 'finds and assign people for view' do
      expect(assigns(:policies)).to eq policies
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end
  end
end
