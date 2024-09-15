Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      resources :addresses, only: [:index]
      post :build_index, to: "addresses#build_index"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end