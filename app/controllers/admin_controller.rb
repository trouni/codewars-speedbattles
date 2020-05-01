class AdminController < ApplicationController
  def home
  end

  def announce
    room = Room.find(announce_params[:room_id])
    options = {
      chat_msg: announce_params[:chat_msg]
    }
    room.announce(:voice, announce_params[:message], **options)
    redirect_to admin_path
  end

  private

  def announce_params
    params.require(:announce).permit(:room_id, :message, :chat_msg)
  end
end
