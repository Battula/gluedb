require 'rails_helper'

describe BrokersController, :dbclean => :after_each do
  login_user

  describe 'GET index' do
    let(:brokers) { [create(:broker)] }
    before { get :index }

    it 'finds and assign brokers for view' do
      expect(assigns(:brokers)).to eq brokers
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end
  end

  describe 'GET show' do
    let(:broker) { create :broker }
    before { get :show, id: broker.id }

    it 'finds and assign broker for view' do
      expect(assigns(:broker)).to eq broker
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end
end
