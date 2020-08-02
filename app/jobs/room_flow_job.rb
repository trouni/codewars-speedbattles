class RoomFlowJob < ApplicationJob
  before_perform do |job|
    set_resources(job)
    if synchronous_execution?
      set_jid
    else
      abort_unless_latest_job
    end
  end

  # # Should not reset jid, otherwise jobs don't expire
  # after_perform do |job|
  #   reset_jid(@scope)
  # end

  private

  def reset_jid(scope = nil)
    @resource.reset_jid(scope)
  end

  def set_jid
    @resource.set_next_jid(job_id, scope: @scope)
  end

  def set_resources(job)
    args = job.arguments.first
    @force = args[:force]
    @room = Room.find(args[:room_id]) if args[:room_id]
    @user = User.find(args[:user_id]) if args[:user_id]
    @battle = Battle.find(args[:battle_id]) if args[:battle_id]
    @room = @battle.room if @battle

    if @user
      @resource = @user
      @scope = @room
    elsif @room
      @resource = @room
    end
  end

  def abort_unless_latest_job
    if @user
      throw(:abort) unless user_is_spectator? || latest_job_for?(@user, scope: @room) || @force
    elsif @room
      throw(:abort) unless latest_job_for?(@room) || @force
    end
  end

  def latest_job_for?(resource, scope: nil)
    # the scope should be an instance
    scope = scope ? "#{scope.class.to_s.downcase}_#{scope.id}" : "default"
    next_jid = resource.settings(:base).next_jid[scope]
    result = next_jid.nil? || next_jid == job_id
    puts "SKIPPING: Job #{job_id} for #{resource.class} ##{resource.id} has expired." unless result
    result
  end

  def user_signed_in?
    @user && @user.persisted?
  end

  def user_is_spectator?
    !user_signed_in?
  end
end
