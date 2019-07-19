class UsersChannel < ApplicationCable::Channel
  def subscribed
    set_room_and_user
    RoomUser.find_or_create_by(room: @room, user: @user)
    stream_from "room_#{@room.id}"
    Message.create_announcement("#{@user.username} joined the war room.", @room.chat.id)
    @user.broadcast_user_status(@room)
  end

  def unsubscribed
    set_room_and_user
    RoomUser.find_by(room: @room, user: @user).destroy
    Message.create_announcement("#{@user.username} left the war room.", @room.chat.id)
    @user.broadcast_user_unsubscribe(@room)
  end

  private

  def set_room_and_user
    @room = Room.find(params[:room_id])
    @user = User.find(params[:user_id])
  end
end
