class StartBattle < RoomFlowJob
  queue_as :critical

  def perform(battle_id:, delay_in_seconds: 0, force: false)
    @battle.start
  end
end
