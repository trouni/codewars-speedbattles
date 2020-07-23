Rails.application.routes.draw do
  root to: 'rooms#index'

  mount ActionCable.server => '/cable'
  devise_for :users, controllers: { registrations: 'registrations' }
  resources :rooms, only: [ :index, :show, :new, :create ]
  get '/settings', to: 'pages#settings', as: :settings
  
  post '/webhook', to: 'codewars#webhook'
  
  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, ->(user) { user.admin } do
    get '/admin', to: 'admin#home', as: :admin
    post '/admin/announce', to: 'admin#announce', as: :announce
    mount Sidekiq::Web => '/sidekiq'
    mount Blazer::Engine, at: "blazer"
  end
  
  # # API Routes
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get '/check_username', to: 'users#valid_username?'
    end
  end
end
