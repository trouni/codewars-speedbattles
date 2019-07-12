json.extract! @room, :id, :name, :moderator_id

json.status @room.status

if @battle
  json.active_battle_id @battle.id
end

json.finished_battles @room.finished_battles.map(&:id)
