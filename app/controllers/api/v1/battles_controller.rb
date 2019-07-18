class Api::V1::BattlesController < Api::V1::BaseController
  # include CodewarsHelper
  # include BattleHelper
  before_action :set_battle, only: %i[show update destroy initialize_invite invite_all invite_last_survivors]

  def show
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
  end

  def create
    @battle = Battle.new(battle_params)
    @room = Room.find(params[:room_id])
    @battle.room = @room
    authorize @battle
    if @battle.save
      render 'api/v1/rooms/show'
    else
      render_error
    end
  end

  def update
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
    @battle.update(battle_params)
    redirect_to room_path(@battle.room)
  end

  def destroy
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
    @battle.destroy
    render 'api/v1/rooms/show'
  end

  def invite_user(user = nil)
    initialize_invite(user)
    @battle_invite.save if @battle_invite.player.eligible?
    render 'api/v1/battles/invite'
  end

  def uninvite_user(user = nil)
    initialize_invite(user)
    @battle_invite.destroy
    render 'api/v1/battles/invite'
  end

  def initialize_invite(user = nil)
    user ||= User.find(params[:user_id])
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    @battle_invite = BattleInvite.find_or_initialize_by(battle: @battle, player: user)
    authorize @battle_invite
    return @battle_invite
  end

  def invite_survivors
    skip_authorization
    return unless @battle.room.last_battle

    @battle.room.last_battle.survivors.each do |user|
      next unless user.eligible?

      initialize_invite(user).save
    end
    render 'api/v1/battles/invite'
  end

  def invite_all
    skip_authorization
    @battle.room.users.each do |user|
      next unless user.eligible?

      initialize_invite(user).save
    end
    render 'api/v1/battles/invite'
  end

  private

  def set_battle
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
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
