json.array! @rooms do |room|
  json.extract! room, :id, :name
  json.moderator room.moderator, partial: 'api/v1/users/user', as: :user
end