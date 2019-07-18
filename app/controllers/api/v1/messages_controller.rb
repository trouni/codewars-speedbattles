class Api::V1::MessagesController < ApplicationController
  acts_as_token_authentication_handler_for User

  def create
    @message = Message.new(message_params)
    authorize @message
    if @message.save
      render partial: 'api/v1/messages/message', locals: { message: @message }
    else
      render_error
    end
  end

  private

  def message_params
    params.require(:message).permit(:chat_id, :user_id, :content)
  end
end
