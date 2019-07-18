class Api::V1::ChatsController < ApplicationController
  def show
    @chat = Chat.find(params[:id] || params[:chat_id])
    authorize @chat
  end
end
