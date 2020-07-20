class ScheduleRandomBattle < ApplicationJob
  queue_as :default

  def perform(room_id:, delay_in_seconds: 0, language: nil, time_limit: nil, kata_options: nil)
    room = Room.find(room_id)
    job = CreateRandomBattle.set(wait: delay_in_seconds.seconds)
                            .perform_later(room_id: room.id, language: language, time_limit: time_limit, kata_options: kata_options)
    room.set_timer(delay_in_seconds.seconds, 'next-battle', job.job_id)
  end
end
