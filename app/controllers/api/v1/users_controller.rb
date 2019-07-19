class Api::V1::UsersController < ApplicationController
  def index
    @room = Room.find(params[:id] || params[:room_id])
    @users = policy_scope(User)
    @users = @room.users
  end
end
