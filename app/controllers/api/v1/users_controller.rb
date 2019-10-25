require 'open-uri'

class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:valid_username?]

  def index
    @room = Room.find(params[:id] || params[:room_id])
    @users = policy_scope(User)
    @users = @room.users
  end

  def valid_username?
    skip_authorization
    open("https://www.codewars.com/api/v1/users/#{params[:username]}")
    render json: { valid: true, exists: User.username_exists?(params[:username]) }
  rescue OpenURI::HTTPError
    render json: { valid: false }
  end

  def fetch_data
    skip_authorization

    if User.find(params[:user_id]).survived?(Battle.find(params[:battle_id]))
      render json: { status: "challenge already completed" }
    elsif User.find(params[:user_id]).last_fetched_at > (DateTime.now - 5.seconds)
      render json: { status: "job already scheduled less than 5 seconds ago" }
    else
      FetchCompletedChallengesJob.perform_later(user_id: params[:user_id], battle_id: params[:battle_id], all_pages: false)
      render json: { status: "fetching job scheduled" }
    end
  end
end
