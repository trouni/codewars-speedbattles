class RoomChannel < ApplicationCable::Channel
  def subscribed
    set_room_and_user
    RoomUser.find_or_create_by(room: @room, user: @user)
    stream_from "room_#{@room.id}_chat"
    stream_from "room_#{@room.id}_battle"
    stream_from "room_#{@room.id}_users"
    broadcast_users @room
  end

  def unsubscribed
    set_room_and_user
    RoomUser.find_by(room: @room, user: @user).destroy
    broadcast_users @room
  end

  # data = {
  #   user_id,
  #   room_id,
  #   subchannel: "user" || "chat" || battle",
  #   payload: {*args}
  # }
  def receive(data)
    set_room_and_user
    case data[:subchannel]
    when "chat"
      # data[:payload] = "message content"
      Message.create(user_id: user.id, chat_id: room.chat.id, content: data[:payload])
      # ActionCable.server.broadcast("room_#{@room.id}_chat", message.api_expose) if message.save
    end
  end

  def create_message(data)
    set_room_and_user
    Message.create(user_id: @user.id, chat_id: @room.chat.id, content: data["message"])
  end

  private

  def set_room_and_user
    @room = Room.find(params[:room_id])
    @user = User.find(params[:user_id])
  end

  def broadcast_users(room)
    ActionCable.server.broadcast(
      "room_#{room.id}_users",
      room.users
    )
  end
end
