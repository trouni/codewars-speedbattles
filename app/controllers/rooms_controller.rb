class RoomsController < ApplicationController
  def index
  end

  def show
    @room = Room.find(params[:id])
    @battle = Battle.find_by(end_time: nil)
  end

  def refresh_user
    FetchCompletedChallengesJob.perform_now(params[:refresh_user][:user_id])
    redirect_to room_path(params[:room_id])
  end
end
