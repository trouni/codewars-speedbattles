class ScheduleEndBattle < SchedulerJob
  queue_as :critical

  def perform(battle_id:, delay_in_seconds: 0, end_at: nil)
    job_to_schedule = EndBattle
    battle = Battle.find(battle_id)
    delay_in_seconds = end_at - Time.now if end_at && Time.now < end_at
    
    battle.room.set_timer(delay_in_seconds.seconds, 'end-battle')
    if delay_in_seconds.zero?
      job_to_schedule.perform_now(battle_id: battle_id)
    else
      scheduled_job = job_to_schedule.set(wait: delay_in_seconds.seconds)
      .perform_later(battle_id: battle_id)
      battle.room.set_next_jid(scheduled_job.job_id)
    end
  end
end
