class ApplicationJob < ActiveJob::Base
  
  private

  def synchronous_execution?
    provider_job_id.nil?
  end
end
