class RoomsController < ApplicationController
  def index
    @rooms = policy_scope(Room)
  end

  def show
    @battle = Battle.find_by(end_time: nil)
    @room = Room.find(params[:id])
    authorize @room
  end
end
