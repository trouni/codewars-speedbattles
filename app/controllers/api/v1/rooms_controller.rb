class Api::V1::RoomsController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User, except: %i[index show]
  before_action :set_room, only: %i[show update]

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

  private

  def set_room
    @room = Room.find(params[:id])
    authorize @room
  end

  def room_params
    params.require(:room).permit(:name, :moderator_id)
  end

  def render_error
    render json: { errors: @room.errors.full_messages }, status: :unprocessable_entity
  end
end
