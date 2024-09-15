require 'rails_helper'

RSpec.describe Api::V1::AddressesController, type: :controller do
  let(:address_index_manager) { instance_double(AddressIndexManager) }

  before do
    allow(AddressIndexManager).to receive(:instance).and_return(address_index_manager)
  end

  describe 'GET #index' do
    let(:sample_results) do
      [
        AddressData.new("100-0001", "東京都", "千代田区", nil, nil, nil, nil, nil),
        AddressData.new("150-0043", "東京都", "渋谷区", "道玄坂", nil, nil, nil, nil)
      ]
    end

    before do
      allow(address_index_manager).to receive(:search).and_return(sample_results)
    end

    context 'with valid query parameter' do
      it 'returns a successful response' do
        get :index, params: { query: '東京' }
        expect(response).to have_http_status(:success)
      end

      it 'returns search results as JSON with correct structure' do
        get :index, params: { query: '東京' }
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)
        expect(json_response.first).to include(
                                         'postal_code' => '100-0001',
                                         'prefecture' => '東京都',
                                         'city' => '千代田区'
                                       )
      end

      it 'calls the search method on AddressIndexManager' do
        expect(address_index_manager).to receive(:search).with('東京')
        get :index, params: { query: '東京' }
      end
    end

    context 'when query parameter is missing' do
      it 'returns a bad request response' do
        get :index
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Query parameter is required')
      end
    end

    context 'when query parameter is empty' do
      it 'returns a bad request response' do
        get :index, params: { query: '' }
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Query parameter cannot be empty')
      end
    end

    context 'when no results are found' do
      before do
        allow(address_index_manager).to receive(:search).and_return([])
      end

      it 'returns an empty array' do
        get :index, params: { query: 'nonexistentplace' }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end

    context 'when an exception occurs during search' do
      before do
        allow(address_index_manager).to receive(:search).and_raise(StandardError.new('Search error'))
      end

      it 'returns an internal server error response' do
        get :index, params: { query: '東京' }
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Search error')
      end
    end
  end

  describe 'POST #build_index' do
    before do
      allow(address_index_manager).to receive(:load_or_build_index)
    end

    it 'returns a successful response' do
      post :build_index
      expect(response).to have_http_status(:success)
    end

    it 'calls the load_or_build_index method on AddressIndexManager' do
      expect(address_index_manager).to receive(:load_or_build_index)
      post :build_index
    end

    context 'when an exception occurs during index building' do
      before do
        allow(address_index_manager).to receive(:load_or_build_index).and_raise(StandardError.new('Index build error'))
      end

      it 'returns an internal server error response' do
        post :build_index
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Index build error')
      end
    end
  end
end