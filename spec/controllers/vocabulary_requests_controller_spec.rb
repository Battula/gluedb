require File.expand_path(File.join(File.dirname(__FILE__), "..", 'rails_helper'))

describe VocabularyRequestsController, :dbclean => :after_each do
  login_user
  let(:mock_vr) { double }

  describe 'GET new' do

    before {
      allow(VocabularyRequest).to receive(:new).and_return(mock_vr)
      get :new
    }

    it 'assigns the vocabulary_request for view' do
      expect(assigns(:vocabulary_request)).to eq mock_vr
    end

    it 'renders the new view' do
      expect(response).to render_template :new
    end
  end

  describe 'POST create' do
    describe 'with valid data' do

      before {
        allow(VocabularyRequest).to receive(:new).and_return(mock_vr)
        allow(mock_vr).to receive(:save).and_return(true)
        post :create
      }

      it 'redirects to the new view' do
        expect(response).to redirect_to new_vocabulary_request_url
      end
    end

    describe 'with invalid data' do
      before {
        allow(VocabularyRequest).to receive(:new).and_return(mock_vr)
        allow(mock_vr).to receive(:save).and_return(false)
        post :create
      }

      it 'renders the new view' do
        expect(response).to render_template :new
      end
    end
  end
end
