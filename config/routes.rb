Rails.application.routes.draw do
  root to: 'rooms#index'

  mount ActionCable.server => '/cable'
  devise_for :users, controllers: { registrations: 'registrations' }
  resources :rooms, only: [ :index, :show, :new, :create ]
  
  post '/webhook', to: 'codewars#webhook'
  
  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  # # API Routes
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get '/check_username', to: 'users#valid_username?'
    end
  end
end
