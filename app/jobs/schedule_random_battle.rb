class ScheduleRandomBattle < SchedulerJob
  queue_as :default

  def perform(room_id:, delay_in_seconds: 0, language: nil, time_limit: nil, kata_options: nil)
    job_to_schedule = CreateRandomBattle
    room = Room.find(room_id)

    room.set_timer(delay_in_seconds.seconds, 'next-battle')
    if delay_in_seconds.zero?
      job_to_schedule.perform_now(room_id: room.id, language: language, time_limit: time_limit, kata_options: kata_options)
    else
      scheduled_job = job_to_schedule.set(wait: delay_in_seconds.seconds)
                                     .perform_later(room_id: room.id, language: language, time_limit: time_limit, kata_options: kata_options)
      room.set_next_jid(scheduled_job.job_id)
    end
  end
end
