class RoomUsersController < ApplicationController
  def create
    room = Room.find(params[:room_id])
    RoomUser.create(user: current_user, room: room)
    redirect_to room_path(room)
  end

  def destroy
    RoomUser.find(params[:id]).destroy
    redirect_to root_path
  end
end
