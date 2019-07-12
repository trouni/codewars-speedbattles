class RoomsController < ApplicationController
  def index
    @rooms = policy_scope(Room)
  end

  def show
    @battle = Battle.find_by(end_time: nil)
    @room = Room.find(params[:id])
    authorize @room
  end

  def refresh_user
    skip_authorization
    FetchCompletedChallengesJob.perform_now(params[:refresh_user][:user_id])
    redirect_to room_path(params[:room_id])
  end
end
