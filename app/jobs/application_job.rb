class ApplicationJob < ActiveJob::Base
  private

  def latest_job_for?(room)
    room.settings(:base).next_event[:jid] == job_id
  end
end
