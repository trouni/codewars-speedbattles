
class BattlesController < ApplicationController
  include CodewarsHelper

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
    @battle = Battle.find(params[:id])
    @battle.update(battle_params)
    redirect_to room_path(@battle.room)
  end

  private

  def battle_params
    params.require(:battle).permit(:sudden_death, :max_survivors, :time_limit)
  end
end
