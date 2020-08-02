class DisconnectUser < RoomFlowJob
  queue_as :default

  def perform(user_id:, room_id: nil, force: false)
    return unless @user && @room

    RoomUser.find_by(room: @room, user: @user)&.destroy

    # Cancel battle invite unless the battle already started
    unless @room.active_battle.nil? || @room.active_battle.started?
      @room.active_battle.invites.find_by(player: @user)&.destroy
    end
  end
end
