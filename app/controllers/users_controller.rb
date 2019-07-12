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
    FetchCompletedChallengesJob.perform_now(params[:user_id])
  end
end
