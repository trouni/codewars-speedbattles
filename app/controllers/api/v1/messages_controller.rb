class Api::V1::MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(chat: @chat, user: current_user, content: params[:content])
    if @message.save

    else
      render_error
    end
  end
end
