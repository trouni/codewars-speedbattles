class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @rooms = policy_scope(Room)
  end

  def show
    @battle = Battle.find_by(end_time: nil)
    @room = Room.find(params[:id])
    authorize @room
  end

  def new
    @room = Room.new
    authorize @room
  end

  def create
    @room = Room.new(room_params)
    @room.moderator = current_user
    authorize @room
    if @room.save
      redirect_to room_path(@room)
    else
      render 'rooms/new'
    end
  end

  private

  def room_params
    params.require(:room).permit(:name)
  end
end
