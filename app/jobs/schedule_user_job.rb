class ScheduleUserJob < SchedulerJob
  queue_as :default
  
  JOBS = {
    connect: ConnectUser,
    disconnect: DisconnectUser
  }

  def perform(job:, user_id:, room_id: nil, delay_in_seconds: 0)
    user = User.find(user_id)
    room = Room.find(room_id) if room_id
    job_to_schedule = JOBS[job.to_sym]

    if delay_in_seconds.zero?
      job_to_schedule.perform_now(user_id: user_id, room_id: room_id)
    else
      scheduled_job = job_to_schedule.set(wait: delay_in_seconds.seconds)
                                     .perform_later(user_id: user_id, room_id: room_id)
      user.set_next_jid(scheduled_job.job_id, scope: room)
    end
  end
end
