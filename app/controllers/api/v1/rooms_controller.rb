class Api::V1::RoomsController < Api::V1::BaseController
  before_action :set_room, only: [ :show ]

  def index
    @rooms = policy_scope(Room)
  end

  def show
    @battle = @room.active_battle
  end

  def refresh_user
    skip_authorization
    FetchCompletedChallengesJob.perform_now(params[:refresh_user][:user_id])
    redirect_to room_path(params[:room_id])
  end

  private

  def set_room
    @room = Room.find(params[:id])
    authorize @room
  end
end
