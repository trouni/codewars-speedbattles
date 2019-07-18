Rails.application.routes.draw do
  root to: 'rooms#index'
  devise_for :users
  resources :users do
    post '/fetch_data', to: 'users#fetch_data'
  end
  resources :rooms do
    resources :battles, only: %i[index create]
    resources :room_users, only: :create
  end
  resources :room_users, only: :destroy
  resources :battles, only: %i[update destroy] do
    resources :battle_invites, only: %i[create]
  end
  resources :battle_invites, only: %i[update destroy]

  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # API Routes
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :rooms, only: [ :index, :show, :create, :update ] do
        resources :battles, only: :create
      end
      resources :battles, only: %i[show update destroy] do
        get '/invite', to: 'battles#invite_user'
        delete '/invite', to: 'battles#uninvite_user'
        get '/invite_all', to: 'battles#invite_all'
        get '/invite_survivors', to: 'battles#invite_survivors'
      end
      resources :challenges, only: :show
      resources :chats, only: :show
      resources :messages, only: :create
    end
  end
end
