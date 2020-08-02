module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def disconnect
      # ActionCable.server.remote_connections.where(current_user: current_user).disconnect
      ScheduleUserJob.perform_now(job: 'disconnect', user_id: current_user.id, delay_in_seconds: 10)
    end

    protected

    def find_verified_user
      return User.find(cookies.signed[:user_id].to_i || 0)
    end
  end
end
