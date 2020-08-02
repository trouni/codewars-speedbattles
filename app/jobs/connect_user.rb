class ConnectUser < RoomFlowJob
  queue_as :default

  def perform(user_id:, room_id: nil, force: false)
    @user.broadcast_settings

    
    if @room
      @room.broadcast_settings(private_to_user_id: @user.id)
      @room.broadcast_users(private_to_user_id: @user.id) unless user_signed_in?
      @room.broadcast_messages(private_to_user_id: @user.id)
      @room.broadcast_active_battle(private_to_user_id: @user.id)
    end

    if user_signed_in? && @room
      RoomUser.where(user: @user).where.not(room: @room).destroy_all
      RoomUser.find_or_create_by(room: @room, user: @user)
      if @room.autonomous?
        # Invite to existing battle if autonomous room
        @room.active_battle&.invitation(user: @user, action: "invite") unless @room.active_battle&.started?
        # Create battle if at_peace and no next event
        ScheduleRandomBattle.perform_now(room_id: @room.id, delay_in_seconds: 20) if @room.auto_schedule_new_battle?
      end
      @room.broadcast_users
    end
  end
end
