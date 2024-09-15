require 'swagger_helper'

RSpec.describe 'Api::V1::Addresses', type: :request do
  path '/api/v1/addresses' do
    get 'Searches addresses' do
      tags 'Addresses'
      produces 'application/json'
      parameter name: :query, in: :query, type: :string, required: true

      response '200', 'addresses found' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   postal_code: { type: :string },
                   prefecture: { type: :string },
                   city: { type: :string },
                   town_area: { type: :string },
                   kyoto_street: { type: :string, nullable: true },
                   block_number: { type: :string, nullable: true },
                   business_name: { type: :string, nullable: true },
                   business_address: { type: :string, nullable: true }
                 },
                 required: %w[postal_code prefecture city town_area]
               }

        let(:query) { '東矢口' }
        run_test!
      end

      response '400', 'bad request' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        let(:query) { '' }
        run_test!
      end

      response '500', 'internal server error' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end
    end
  end

  path '/api/v1/build_index' do
    post 'Builds the address index' do
      tags 'Addresses'
      produces 'application/json'

      response '200', 'index built successfully' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               },
               required: ['message']

        run_test!
      end

      response '500', 'internal server error' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end
    end
  end
end