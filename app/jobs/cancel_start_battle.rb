class CancelStartBattle < RoomFlowJob
  queue_as :default

  def perform(battle_id:)
    battle = Battle.find(battle_id)
    return if battle.started?

    # battle.room.clear_next_event!(only: 'start-battle')
  end
end
