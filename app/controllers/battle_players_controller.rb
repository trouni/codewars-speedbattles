class BattlePlayersController < ApplicationController
  def create
    @battle = Battle.find(params[:battle_id])
    @player = User.find(params[:battle_player][:player])
    BattlePlayer.create(battle: @battle, player: @player)
    redirect_to room_path(@battle.room)
  end

  def update

  end

  def destroy
    @battle_player = BattlePlayer.find(params[:id]).destroy
    redirect_to room_path(@battle_player.battle.room)
  end
end
