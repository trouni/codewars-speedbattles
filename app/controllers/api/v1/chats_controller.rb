class Api::V1::ChatsController < ApplicationController
  def show
    @chat = Chat.find(params[:id] || params[:chat_id])
    @messages = @chat.messages.order(created_at: :desc).limit(50)
    authorize @chat
  end
end
