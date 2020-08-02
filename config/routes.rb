Rails.application.routes.draw do
  root to: 'pages#home'

  mount ActionCable.server => '/cable'
  devise_for :users, controllers: { registrations: 'registrations', sessions: 'sessions' }
  resources :rooms, only: [ :index, :show, :new, :create ]
  get '/setup-webhook', to: 'pages#webhook_help', as: :webhook_help
  get '/sign_out_all', to: 'pages#sign_out_all', as: :sign_out_all
  
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
