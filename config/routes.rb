Rails.application.routes.draw do
  root to: 'rooms#index'
  mount ActionCable.server => '/cable'
  devise_for :users, controllers: { registrations: 'registrations' }
  # resources :users do
  #   post '/fetch_data', to: 'users#fetch_data'
  # end
  resources :rooms, only: [ :index, :show, :new, :create ]

  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # # API Routes
  namespace :api, defaults: { format: :json } do
  #   # mount ActionCable.server => '/cable'
    namespace :v1 do
  #     resources :rooms, only: [ :index, :show, :create, :update ] do
  #       get '/leaderboard', to: 'rooms#leaderboard'
  #       resources :battles, only: :create
  #       resources :users, only: :index
  #     end
  #     resources :battles, only: %i[show update destroy] do
  #       get '/invitation', to: 'battles#invitation'
  #       get '/launch', to: 'battles#launch'
  #       # get '/results', to: 'battles#results'
  #       # get '/completed_battle', to: 'battles#completed_battle'
  #     end
  #     resources :users do
  #       get '/fetch_data', to: 'users#fetch_data'
  #     end
      get '/check_username', to: 'users#valid_username?'
  #     resources :challenges, only: :show
  #     resources :chats, only: :show
  #     resources :messages, only: :create
    end
  end
end
