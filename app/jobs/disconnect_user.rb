class DisconnectUser < ApplicationJob
  queue_as :default

  def perform(user_id:, room_id: nil, force: false)
    user = User.find(user_id)
    room = Room.find(room_id) if room_id
    scope = "room_#{room_id}" if room_id
    return unless user && room && (latest_job_for?(user, scope: scope) || force)

    RoomUser.find_by(room: room, user: user)&.destroy

    # Cancel battle invite unless the battle already started
    unless room.active_battle&.started?
      room.active_battle&.battle_invites.find_by(player: user)&.destroy
    end
  end
end
