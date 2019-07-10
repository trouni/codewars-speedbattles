class BattlesController < ApplicationController
  include CodewarsHelper
  before_action :set_battle, only: %i[update destroy]

  def show
  end

  def create
    @room = Room.find(params[:room_id])
    parsed_url = parse_kata_url(params[:other][:challenge_url])
    @battle = Battle.new(fetch_kata_info(parsed_url))
    @battle.room = @room
    @battle.save
    redirect_to room_path(@room)
  end

  def update
    @battle.update(battle_params)
    redirect_to room_path(@battle.room)
  end

  def destroy
    @battle.destroy
    redirect_to room_path(@battle.room)
  end

  private

  def set_battle
    @battle = Battle.find(params[:id])
  end

  def battle_params
    params.require(:battle).permit(:sudden_death, :max_survivors, :time_limit, :start_time)
  end
end
