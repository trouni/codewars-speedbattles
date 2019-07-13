class BattleInvitesController < ApplicationController
  before_action :set_battle_invite, only: %i[update destroy]

  def create
    @battle = Battle.find(params[:battle_id])
    @player = User.find(params[:battle_invite][:player])
    if @player.eligible?(@battle)
      @battle_invite = BattleInvite.new(battle: @battle, player: @player)
      authorize @battle_invite
      @battle_invite.save
    else
      skip_authorization
      flash[:alert] = "#{@player.username} already completed the kata and can not participate."
    end
    redirect_to room_path(@battle.room)
  end

  def update
    @battle_invite.update(battle_invite_params)
    redirect_to room_path(@battle_invite.battle.room)
  end

  def destroy
    @battle_invite.destroy
    redirect_to room_path(@battle_invite.battle.room)
  end

  private

  def battle_invite_params
    params.require(:battle_invite).permit(:confirmed)
  end

  def set_battle_invite
    @battle_invite = BattleInvite.find(params[:id])
    authorize @battle_invite
  end
end
