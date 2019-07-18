# ROOM
json.extract! @room, :id, :name
json.moderator @room.moderator, partial: 'api/v1/users/user', as: :user
# json.status @room.battle_status

# USERS
json.users @room.users do |user|
  json.partial! user, partial: 'api/v1/users/user', as: :user
end

# ACTIVE BATTLE
if @room.active_battle?
  json.active_battle @room.active_battle, partial: 'api/v1/battles/battle', as: :battle
end

# PAST BATTLES
json.finished_battles @room.finished_battles, partial: 'api/v1/battles/battle', as: :battle
