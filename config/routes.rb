Rails.application.routes.draw do
  get 'users/index'
  get 'users/show'
  get 'users/edit'
  get 'users/update'
  get 'users/destroy'
  get 'rooms/index'
  get 'rooms/show'
  get 'battles/show'
  devise_for :users
  root to: 'pages#home'
  resources :rooms
  resources :battles, only: :index
end
