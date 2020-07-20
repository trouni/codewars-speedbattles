class EndBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, force: false)
    battle = Battle.find(battle_id)
    return unless latest_job_for?(battle.room) || force

    battle.terminate
    # battle.room.clear_next_event!(only: 'end-battle')
  end
end
