json.array! @users do |user|
  json.partial! user, partial: 'api/v1/users/user', as: :user
end