class ScheduleUserJob < ApplicationJob
  queue_as :default
  JOBS = {
    connect: ConnectUser,
    disconnect: DisconnectUser
  }

  def perform(job:, user_id:, room_id: nil, delay_in_seconds: 0)
    user = User.find(user_id)
    room = Room.find(room_id) if room_id
    scope = room_id ? "room_#{room_id}" : nil
    job_to_schedule = JOBS[job.to_sym]

    scheduled_job = job_to_schedule.set(wait: delay_in_seconds.seconds)
                                   .perform_later(user_id: user.id, room_id: room&.id)
    
    user.set_next_jid(scheduled_job.job_id, scope: scope)
  end
end
