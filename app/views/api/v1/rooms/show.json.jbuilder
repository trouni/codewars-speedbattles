json.extract! @room, :id, :name
json.moderator @room.moderator, partial: 'api/v1/users/user', as: :user

json.status @room.battle_status

if @room.active_battle?
  json.active_battle_id @room.active_battle.id
end

json.users @room.users, partial: 'api/v1/users/user', as: :user

json.finished_battles @room.finished_battles, :id, :end_time, :winner_id, :challenge_name, :challenge_rank

