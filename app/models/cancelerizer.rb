module Cancelerizer
  extend ActiveSupport::Concern
  module ClassMethods
    def cancel_perform(*args)
      # sleep rand(1..9)
      Sidekiq::ScheduledSet.new.each { |job| job.delete if same_job?(job, args) }
      Sidekiq::Queue.new.each { |job| job.delete if same_job?(job, args) }
    end

    alias_method :cancel_it, :cancel_perform

    private

    def same_job?(job, args)
      return false unless job.args.count == args.count

      arg_pairings = job.args.zip args
      name == job.klass && arg_pairings.all? { |job_arg, arg| job_arg == arg }
    end
  end
end
