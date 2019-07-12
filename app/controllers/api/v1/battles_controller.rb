class BattlesController < ApplicationController
  include CodewarsHelper
  include BattleHelper
  before_action :set_battle, only: %i[show update destroy]

  def show
  end

  def create
    @room = Room.find(params[:room_id])
    parsed_url = parse_kata_url(params[:other][:challenge_url])
    @battle = Battle.new(fetch_kata_info(parsed_url))
    @battle.room = @room
    authorize @battle
    if @battle.save
      redirect_to room_path(@room)
    else
      render 'rooms/show'
    end
  end

  def update
    @battle.update(battle_params)
    redirect_to room_path(@battle.room)
  end

  def destroy
    @battle.destroy
    redirect_to room_path(@battle.room)
  end

  def fetch_challenge
  end

  private

  def set_battle
    @battle = Battle.find(params[:id])
    authorize @battle
  end

  def battle_params
    params.require(:battle).permit(:sudden_death, :max_survivors, :time_limit, :start_time, :end_time)
  end
end
