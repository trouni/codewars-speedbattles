class UsersController < ApplicationController
  def index
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def fetch_data
    skip_authorization
    FetchCompletedChallengesJob.perform_later(params[:id] || params[:user_id])
    render json: { status: "success" }
  end
end
