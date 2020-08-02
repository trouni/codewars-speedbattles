class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @public_rooms = policy_scope(Room).where(private: false).order(created_at: :asc).map(&:settings_hash).sort_by { |room| -room[:users_count] }
    @private_rooms = policy_scope(Room).where(private: true).order(created_at: :asc).map(&:settings_hash).sort_by { |room| -room[:users_count] }
  end

  def show
    # @battle = Battle.includes(:room).find_by(end_time: nil)
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
