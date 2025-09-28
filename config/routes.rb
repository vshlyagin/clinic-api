Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  root to: redirect("/api-docs")

  namespace :api do
    namespace :v1 do
      resources :doctors
      resources :patients do
        member do 
          post :calculate_bmr
          get :bmr_history
          get :calculate_bmi
        end
      end
    end
  end
end
