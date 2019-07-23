class BattleChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_from "warroom_#{room.id}"
  end
end
