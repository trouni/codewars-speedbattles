class StartBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, delay_in_seconds: 0, force: false)
    battle = Battle.find(battle_id)
    return unless latest_job_for?(battle.room) || force

    battle.start
    # battle.room.clear_next_event!(only: 'start-battle')
  end
end
