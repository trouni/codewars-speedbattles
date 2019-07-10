class RoomsController < ApplicationController
  def index
  end

  def show
    @room = Room.find(params[:id])
    @battle = Battle.find_by(archived: false)
  end
end
