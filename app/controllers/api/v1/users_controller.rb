class Api::V1::UsersController < ApplicationController
  def index
    @room = Room.find(params[:id] || params[:room_id])
    @users = policy_scope(User)
    @users = @room.users
  end

  def fetch_data
    skip_authorization
    FetchCompletedChallengesJob.perform_now(params[:id] || params[:user_id], params[:battle_id])
    render json: { status: "success" }
  end
end
