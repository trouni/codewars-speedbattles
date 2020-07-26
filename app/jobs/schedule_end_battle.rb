class ScheduleEndBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, delay_in_seconds: 0, end_at: nil)
    battle = Battle.find(battle_id)
    delay_in_seconds = end_at - Time.now if end_at && Time.now < end_at
    job = EndBattle.set(wait: delay_in_seconds.seconds).perform_later(battle_id: battle_id)
    battle.room.set_timer(delay_in_seconds.seconds, 'end-battle', job.job_id)
  end
end
