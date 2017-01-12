require 'rails_helper'

describe CarriersController, :dbclean => :after_each do
  login_user

  describe 'GET index' do
    let(:carriers) { [create(:carrier)] }
    before { get :index }

    it 'finds and assign carriers for view' do
      expect(assigns(:carriers)).to eq carriers
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end
  end

  describe 'GET show' do
    let(:carrier) { create :carrier }
    before { get :show, id: carrier.id }

    it 'finds and assign carrier for view' do
      expect(assigns(:carrier)).to eq carrier
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end
end
