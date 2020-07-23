class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :connected_webhook?, except: [:index]

  def index
    @rooms = policy_scope(Room).order(created_at: :asc)
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

  def connected_webhook?
    if current_user.present? && !current_user.connected_webhook?
      flash[:notice] = "Please set up the Codewars webhook to continue..."
      redirect_to edit_user_registration_path
    end
  end
end
