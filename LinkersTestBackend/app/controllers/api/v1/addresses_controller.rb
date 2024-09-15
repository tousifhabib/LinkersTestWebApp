module Api
  module V1
    class AddressesController < ApplicationController
      def index
        query = params[:query]
        if query.nil?
          render json: { error: 'Query parameter is required' }, status: :bad_request
          return
        elsif query.strip.empty?
          render json: { error: 'Query parameter cannot be empty' }, status: :bad_request
          return
        end

        begin
          results = AddressIndexManager.instance.search(query)
          render json: results.map(&:to_h)
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      def build_index
        begin
          AddressIndexManager.instance.load_or_build_index
          render json: { message: 'Index built successfully' }
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
