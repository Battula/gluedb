require 'rails_helper'

describe EmployersController, :dbclean => :after_each do
  login_user

  describe 'GET new' do
    before { get :new, format: 'html' }
    it 'assigns a new instance for the view' do
      expect(assigns(:employer)).not_to be_nil
    end

    it 'renders the new template' do
      expect(response).to render_template :new
    end
  end

  describe 'POST create' do
    context 'with valid attributes' do
      let(:attributes) { attributes_for :employer }
=begin
      it 'saves the record' do
        expect {
          post :create, employer: attributes
        }.to change(Employer, :count).by 1
      end
=end

      it 'redirects to employer show' do
        post :create, employer: attributes
        expect(response).to redirect_to Employer.last
      end

    end
    context 'with invalid attributes' do
      let(:invalid_attributes) { attributes_for :invalid_employer }
=begin
      it 'does not save' do
        expect {
          post :create, employer: invalid_attributes
        }.not_to change(Employer, :count).by 1
      end
=end

      it 'renders the new view' do
        post :create, employer: invalid_attributes
        expect(response).to render_template :new
      end
    end
  end

  describe 'GET index' do
    let(:employers) { [create(:employer)] }
    before { get :index }

    it 'finds and assign employers for view' do
      expect(assigns(:employers)).to eq employers
    end

    it 'renders the index view' do
      expect(response).to render_template :index
    end

  end

  describe 'GET show' do
    let(:employer) { create :employer }
    before { get :show, id: employer.id }

    it 'finds and assign employer for view' do
      expect(assigns(:employer)).to eq employer
    end

    it 'renders the show view' do
      expect(response).to render_template :show
    end
  end

  describe 'GET edit' do
    let(:employer) { create :employer }
    before { get :edit, id: employer.id }

    it 'finds and assign employer for view' do
      expect(assigns(:employer)).to eq employer
    end

    it 'renders the edit view' do
      expect(response).to render_template :edit
    end
  end

  describe 'PUT update' do
    let(:employer) { create :employer }

    context 'with valid attributes' do
      before do
        put :update, format: 'html', id: employer.id, employer: { name: 'Changed' }
      end

      it 'finds the requested employer' do
        expect(assigns(:employer)).to eq employer
      end

      it 'redirects to the employer show' do
        expect(response).to redirect_to employer
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { attributes_for :invalid_employer }
      before do
        put :update, id: employer.id, employer: invalid_attributes
      end

      it 'finds the requested employer' do
        expect(assigns(:employer)).to eq employer
      end

      it 'does not save the changes' do
        employer.reload
        expect(employer.name).not_to eq ' '
      end

      it 'renders the edit view' do
        expect(response).to render_template :edit
      end
    end
  end

  describe 'DELETE destroy' do
    before { @employer = create :employer }

    it 'deletes the employer' do
      expect { delete :destroy, id: @employer.id
        }.to change(Employer, :count).by -1
    end

    it 'redirects to employer index' do
      delete :destroy, id: @employer.id
      expect(response).to redirect_to employers_path
    end
  end

  describe 'GET group' do
    let(:employer) { create :employer }
    before { get :group, id: employer.id, format: :xml}

    it 'finds and assign employer for view' do
      expect(assigns(:employer)).to eq employer
    end

    it 'renders the group template' do
      expect(response).to render_template :group
    end
  end
end
