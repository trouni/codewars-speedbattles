class ConnectUser < ApplicationJob
  queue_as :default

  def perform(user_id:, room_id: nil, force: false)
    user = User.find(user_id)
    room = Room.find(room_id) if room_id
    scope = "room_#{room_id}" if room_id
    return unless user && (latest_job_for?(user, scope: scope) || force)

    user.broadcast_settings if user
    
    if room
      RoomUser.where(user: user).where.not(room: room).destroy_all
      RoomUser.find_or_create_by(room: room, user: user)
      room.broadcast_settings(private_to_user_id: user.id)
      room.broadcast_users
      room.broadcast_messages(private_to_user_id: user.id)
      room.broadcast_active_battle(private_to_user_id: user.id)
      
      if room.autonomous?
        # Invite to existing battle if autonomous room
        room.active_battle&.invitation(user: user, action: "invite") unless room.active_battle&.started?
        # Create battle if at_peace and no next event
        ScheduleRandomBattle.perform_now(room_id: room.id, delay_in_seconds: 20) unless room.unfinished_battle? || room.next_event?
      end
    end
  end
end
