require 'rails_helper'

describe Api::V1::PeopleController, :dbclean => :after_each do
  login_user

  describe 'GET show' do
    let(:person) { create :person }
    before { get :show, id: person.id, format: 'xml' }

    it 'finds and assign person for view' do
      expect(assigns(:person)).to eq person
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end

  describe 'GET index' do
    let(:people) { [ create(:person) ] }
    before { get :index, format: 'xml' }

    it 'finds and assign people for view' do
      expect(assigns(:people)).to eq people
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end
  end
end
