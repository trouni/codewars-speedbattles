class Api::V1::UsersController < ApplicationController
  def index
    @room = Room.find(params[:id] || params[:room_id])
    @users = policy_scope(User)
    @users = @room.users
  end

  def fetch_data
    skip_authorization

    if Battle.find(params[:battle_id]).survived?(User.find(params[:user_id]))
      render json: { status: "challenge already completed" }
    elsif User.find(params[:user_id]).last_fetched_at > (DateTime.now - 5.seconds)
      render json: { status: "job already scheduled less than 5 seconds ago" }
    else
      FetchCompletedChallengesJob.perform_later(params[:id] || params[:user_id], params[:battle_id])
      render json: { status: "fetching job scheduled" }
    end
  end
end
