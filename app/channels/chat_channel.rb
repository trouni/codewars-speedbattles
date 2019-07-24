class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:chat_id]}"
  end

  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:chat_id]}", data)
  end
end
