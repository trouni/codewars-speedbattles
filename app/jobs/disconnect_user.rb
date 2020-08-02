class DisconnectUser < RoomFlowJob
  queue_as :default

  def perform(user_id:, room_id: nil, force: false)
    return unless @user

    RoomUser.where(user: @user)&.destroy_all
  end
end
