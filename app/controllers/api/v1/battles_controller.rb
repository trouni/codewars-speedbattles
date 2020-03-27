class Api::V1::BattlesController < Api::V1::BaseController
  # include CodewarsHelper
  # include BattleHelper
  # before_action :set_battle, only: %i[show update destroy initialize_invite invite_all invite_last_survivors]

  def show
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
  end

  def create
    @room = Room.find(params[:room_id])
    @battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    authorize @battle
    if @battle.update(battle_params)
      render 'api/v1/rooms/show'
    else
      render_error
    end
  end

  def update
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
    @battle.update(battle_params)
  end

  def destroy
    @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
    authorize @battle
    @battle.destroy
    render json: { status: "success" }
    # render 'api/v1/rooms/show'
  end

  # def launch
  #   @battle = Battle.find(params[:id] || params[:battle_id])
  #   authorize @battle
  #   if params[:perform] == 'end'
  #     final_end_time = @battle.time_limit ? [@battle.start_time + @battle.time_limit.minutes, Time.now].min : Time.now
  #     @battle.update(end_time: final_end_time) unless @battle.end_time
  #     @battle.broadcast_action('end-battle')
  #     @battle.defeated_players.each(&:async_fetch_codewars_info)
  #   else
  #     countdown = params[:countdown].to_i.seconds
  #     @battle.update(start_time: Time.now + countdown) unless @battle.start_time
  #     @battle.broadcast_action('start-countdown', countdown: params[:countdown].to_i)
  #     @battle.battle_invites.where(confirmed: false).destroy_all
  #   end
  #   render json: { action: params[:perform], status: "success" }
  # end

  # def invitation(battle = nil, user = nil, action = nil)
  #   # skip_authorization
  #   battle ||= Battle.find(params[:battle_id])
  #   user ||= User.find(params[:user_id]) if params[:user_id]
  #   action ||= params[:perform]
  #   case action
  #   when "uninvite"
  #     uninvite_user(user, battle)
  #   when "confirm"
  #     confirm_user(user, battle)
  #   when "all"
  #     invite_all(battle)
  #   when "survivors"
  #     invite_survivors(battle)
  #   else
  #     invite_user(user, battle)
  #   end
  # end

  # def invite_user(user, battle = nil)
  #   battle ||= user.active_battle
  #   battle_invite = BattleInvite.find_or_initialize_by(battle: battle, player: user)
  #   authorize battle_invite
  #   battle_invite.save if battle_invite.player.eligible?
  # end

  # def uninvite_user(user, battle = nil)
  #   battle ||= user.active_battle
  #   battle_invite = BattleInvite.find_by(battle: battle, player: user)
  #   authorize battle_invite
  #   battle_invite&.destroy
  # end

  # def confirm_user(user, battle = nil)
  #   battle ||= user.active_battle
  #   battle_invite = BattleInvite.find_by(battle: battle, player: user)
  #   authorize battle_invite
  #   battle_invite&.update(confirmed: !battle_invite.confirmed)
  # end

  # def invite_all(battle)
  #   skip_authorization
  #   battle.room.users.each do |user|
  #     next unless user.eligible?

  #     invite_user(user)
  #   end
  #   render 'api/v1/users/index'
  # end

  # def invite_survivors(battle)
  #   skip_authorization
  #   return unless battle.room.last_battle

  #   battle.room.last_battle.survivors.each do |user|
  #     next unless user.eligible?

  #     invite_user(user)
  #   end
  #   render 'api/v1/users/index'
  # end

  # def completed_battle
  #   skip_authorization
  #   battle ||= Battle.find(params[:battle_id])
  #   user ||= User.find(params[:user_id])
  #   render json: battle.completed_challenge(user).api_expose
  # end

  # def results
  #   skip_authorization
  #   @battle = Battle.find(params[:battle_id])
  #   render json: @battle.results
  # end

  private

  # def set_battle
  #   @battle = Battle.find(params[:id] || params[:battle_id]) || user.active_battle
  #   authorize @battle
  # end

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
