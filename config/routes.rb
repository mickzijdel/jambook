Rails.application.routes.draw do
  root "rooms#show"

  resource :room, only: :show do
    scope module: :rooms do
      resource :key, only: :update
    end
  end

  resources :songs do
    scope module: :songs do
      resource :play, only: :create
      resource :notes, only: %i[ edit update ]
    end
  end

  resource :session
  resource :guest_access, only: %i[ new create ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
