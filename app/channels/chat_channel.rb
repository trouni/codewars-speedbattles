class ChatChannel < ApplicationCable::Channel
  def subscribed
    chat = Chat.find(params[:chat_id])
    stream_from "chat_#{chat.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
