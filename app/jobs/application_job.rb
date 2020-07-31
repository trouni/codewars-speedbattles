class ApplicationJob < ActiveJob::Base
  private

  def latest_job_for?(resource, scope: "default")
    next_jid = scope ? resource.settings(:base).next_jid[scope] : resource.settings(:base).next_jid
    result = next_jid == job_id
    puts "SKIPPING: Job #{job_id} for #{resource.class} ##{resource.id} has expired." unless result
    result
  end
end
