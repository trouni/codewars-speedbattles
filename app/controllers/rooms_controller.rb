class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :connected_webhook?

  def index
    @public_rooms = policy_scope(Room).where(private: false).order(created_at: :asc)
    @private_rooms = policy_scope(Room).where(private: true).order(created_at: :asc)
    render layout: 'vue_application'
  end

  def show
    # @battle = Battle.includes(:room).find_by(end_time: nil)
    @room = Room.find(params[:id])
    authorize @room
    render layout: 'vue_application'
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
    return if params[:action] == 'index' && params[:settings] == 'show'

    if current_user.present? && !current_user.connected_webhook? && !current_user.admin?
      flash[:notice] = "Please set up the Codewars webhook to continue..."
      redirect_to action: :index, settings: :show
    end
  end
end
