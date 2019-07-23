class Api::V1::RoomsController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User, except: %i[index show]
  before_action :set_room, only: %i[show update leaderboard]
  before_action :set_expand, only: %i[index show]

  def index
    @rooms = policy_scope(Room)
  end

  def show
  end

  def create
    @room = Room.new(room_params)
    authorize @room

    if @room.save
      render :show
    else
      render_error
    end
  end

  def update
    if @room.update(room_params)
      render :show
    else
      render_error
    end
  end

  def leaderboard
    render json: @room.leaderboard
  end

  private

  def set_room
    @room = Room.find(params[:id] || params[:room_id])
    authorize @room
  end

  def set_expand
    @expand = params[:expand].split(",") if params[:expand]
  end

  def room_params
    params.require(:room).permit(:name, :moderator_id)
  end

  def render_error
    render json: { errors: @room.errors.full_messages }, status: :unprocessable_entity
  end
end
