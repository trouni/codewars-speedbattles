class Api::V1::BattlesController < Api::V1::BaseController
  include CodewarsHelper
  include BattleHelper
  before_action :set_battle, only: %i[show update destroy]

  def show
  end

  def create
    @battle = Battle.new(battle_params)
    @room = Room.find(params[:room_id])
    @battle.room = @room
    authorize @battle
    if @battle.save
      render :show
    else
      render_error
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
    params.require(:battle).permit(
      :challenge_id,
      :challenge_url,
      :challenge_description,
      :challenge_name,
      :challenge_rank,
      :time_limit,
      :start_time,
      :end_time
    )
  end
end
