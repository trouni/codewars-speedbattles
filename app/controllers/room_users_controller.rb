class RoomUsersController < ApplicationController
  def create
    room = Room.find(params[:room_id])
    @room_user = RoomUser.find_by(room: params[:room_id], user: current_user) || @room_user = RoomUser.new(user: current_user, room: room)
    authorize @room_user
    if @room_user.save
      redirect_to room_path(room)
    else
      redirect_to rooms_path
    end
  end

  def destroy
    RoomUser.find(params[:id]).destroy
    redirect_to root_path
  end
end
