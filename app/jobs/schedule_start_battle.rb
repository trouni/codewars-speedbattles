class ScheduleStartBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, delay_in_seconds: 0)
    battle = Battle.find(battle_id)
    job = StartBattle.set(wait: delay_in_seconds.seconds).perform_later(battle_id: battle_id)
    battle.room.set_timer(delay_in_seconds.seconds, 'start-battle', job.job_id)
  end
end
