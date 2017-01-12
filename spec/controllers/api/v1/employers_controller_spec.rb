require 'rails_helper'

describe Api::V1::EmployersController, :type => :controller, :dbclean => :after_each do
  login_user

  describe 'GET show' do
    let(:employer) { create :employer }
    before { get :show, id: employer.id, format: 'xml' }

    it 'finds and assign employer for view' do
      expect(assigns(:employer)).to eq employer
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end

  describe 'GET index' do
    let(:employers) { [ create(:employer) ] }
    before { get :index, format: 'xml' }

    it 'finds and assign people for view' do
      expect(assigns(:employers)).to eq employers
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end
  end
end
