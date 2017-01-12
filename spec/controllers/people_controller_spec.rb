require 'rails_helper'

describe PeopleController, :dbclean => :after_each do
  before(:each) do
    @user = create :user, :admin
    sign_in @user
  end

  describe 'GET new' do
    before { get :new, format: 'html' }
    it 'assigns a new instance for the view' do
      expect(assigns(:person)).not_to be_nil
    end

    it 'renders the new template' do
      expect(response).to render_template :new
    end
  end
=begin
  describe 'POST create' do
    context 'with valid attributes' do
      let(:person) { build(:person) }
      let(:attributes) { person.attributes }

      it 'saves the record' do
        expect {
          post :create, person: attributes
        }.to change(Person, :count).by 1
      end

      it 'redirects to person show' do
        post :create, person: attributes
        expect(response).to redirect_to person.family
      end

    end
    context 'with invalid attributes' do
      let(:invalid_attributes) { attributes_for :invalid_person }
      it 'does not save' do
        expect {
          post :create, person: invalid_attributes
        }.not_to change(Person, :count).by 1
      end
      it 'renders the new view' do
        post :create, person: invalid_attributes
        expect(response).to render_template :new
      end
    end
  end
=end

  describe 'GET show' do
    let(:person) { create :person }
    before { get :show, id: person.id }

    it 'finds and assign person for view' do
      expect(assigns(:person)).to eq person
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end

  describe 'GET edit' do
    let(:person) { create :person }
    before { get :edit, id: person.id }

    it 'finds and assign person for view' do
      expect(assigns(:person)).to eq person
    end

    it 'renders the edit view' do
      expect(response).to render_template :edit
    end
  end

  describe 'PUT update' do
    let(:person) { create :person }

    context 'with valid attributes' do
      before do
        put :update, format: 'html', id: person.id, person: { name_first: 'Changed' }
      end

      it 'finds the requested person' do
        expect(assigns(:person)).to eq person
      end

      it 'redirects to the person show' do
        expect(response).to redirect_to person
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { attributes_for :invalid_person }
      before do
        put :update, id: person.id, person: invalid_attributes
      end

      it 'finds the requested person' do
        expect(assigns(:person)).to eq person
      end

      it 'does not save the changes' do
        person.reload
        expect(person.name_first).not_to eq ' '
      end

      it 'renders the edit view' do
        expect(response).to render_template :edit
      end
    end
  end

  describe 'PUT compare' do
    let(:person) { create :person }
    let(:new_attributes) { attributes_for :person }

    context 'with valid attributes' do
      before { put :compare, format: 'html', id: person.id, person: new_attributes }

      # it 'finds the requested person' do
      #   expect(assigns(:person)).to eq person
      # end

      # it 'stores the updates for later submission' do
      #   expect(assigns(:updates)).to include(new_attributes)
      # end

      # it 'stores the delta' do
      #   expect(assigns(:delta)).not_to be_nil
      # end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { attributes_for :invalid_person }
      before { put :update, id: person.id, person: invalid_attributes }

      it 'finds the requested person' do
        expect(assigns(:person)).to eq person
      end

      it 'renders the edit view' do
        expect(response).to render_template :edit
      end
    end
  end


  describe 'DELETE destroy' do
    before { @person = create :person }

    it 'deletes the person' do
      expect { delete :destroy, id: @person.id
        }.to change(Person, :count).by -1
    end

    it 'redirects to person index' do
      delete :destroy, id: @person.id
      expect(response).to redirect_to people_path
    end
  end

end
