class RoomChannel < ApplicationCable::Channel
  include CodewarsHelper

  def subscribed
    set_current_user
    set_room

    # Disconnect from all other rooms
    ActionCable.server.remote_connections.where(current_user: @current_user).disconnect
    stop_all_streams
    
    stream_from "user_#{@current_user.id}" if @current_user
    stream_from "room_#{@room.id}" if @room
    ScheduleUserJob.perform_now(job: 'connect', user_id: @current_user&.id, room_id: @room&.id)
  end

  def unsubscribed
    set_room
    set_current_user
    stop_all_streams
    ScheduleUserJob.perform_now(job: 'disconnect', user_id: @current_user.id, room_id: @room&.id, delay_in_seconds: 10)
  end

  # =============
  #     CHAT
  # =============

  def create_message(data)
    set_room
    set_current_user
    if data["announcement"]
      @room.chat.create_announcement(data["message"]) if @current_user == @room.moderator
    else
      Message.create(user_id: @current_user.id, chat_id: @room.chat.id, content: data["message"].strip)
    end
  end

  # =============
  #    BATTLES
  # =============

  def available_katas_count(data)
    set_room
    set_current_user
    kata_options = data['kata'].transform_keys(&:to_sym)
    @room.broadcast(subchannel: "battles", payload: { action: 'katas-count', count: @room.available_katas(**kata_options).count }, private_to_user_id: @current_user.id)
  end

  def create_battle(data)
    set_room
    @room.update_settings(auto_invite: data['auto_invite'])
    battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    battle.time_limit = data["time_limit"] if data["time_limit"]&.positive?
    battle.challenge_language = data['language']
    kata = Kata.find_by(codewars_id: data['challenge_id']) || Kata.find_by(slug: data['challenge_id'])
    kata ? battle.update(kata: kata) : @room.broadcast_active_battle
  end

  def create_random_battle(data)
    set_room
    kata_options = data['kata'].transform_keys(&:to_sym)
    @room.update_settings(katas: kata_options.except(:language), auto_invite: data['auto_invite'])
    ScheduleRandomBattle.perform_now(room_id: @room.id, language: data['language'], time_limit: data['time_limit'], kata_options: kata_options)
  end

  def update_battle(data)
    set_room
    battle = Battle.find(data["battle_id"])
    case data["battle_action"]
    when "start" then ScheduleStartBattle.perform_now(battle_id: battle.id, delay_in_seconds: data["countdown"].to_i)
    when "end"
      end_at = battle.time_limit&.positive? ? [battle.start_time + battle.time_limit.seconds, Time.now].min : Time.now
      battle.terminate(end_at: end_at)
    when "ended-by-user"
      battle = @room.active_battle
      ScheduleEndBattle.perform_now(battle_id: battle.id, delay_in_seconds: 0)
      # battle.time_limit = (Time.now - battle.start_time + 15.seconds).round
      # @room.broadcast(subchannel: "battles", payload: { action: "active", battle: battle.api_expose })
    when "update"
      battle.update(data["battle"])
      ScheduleEndBattle.perform_now(battle_id: battle.id, end_at: battle.start_time + battle.time_limit.seconds) if battle.time_limit.positive? && battle.ongoing?
    end
  end

  def delete_battle(data)
    set_room
    Battle.find(data["battle_id"]).destroy
    @room.broadcast_active_battle
  end

  def invitation(data)
    battle = Battle.find(data["battle_id"])
    user = User.find(data["user_id"]) if data["user_id"]
    battle.invitation(user: user, action: data["invite_action"])
  end

  # =============
  #     SETTINGS
  # =============

  def update_user_settings(data)
    if data['user']
      set_current_user
      @current_user.update(name: data['user']['name'])
      @current_user.update_settings(data['user'].except('name'))
    end
  end

  def update_room_settings(data)
    if data['room']
      set_room
      @room.update(name: data['room']['name'])
      @room.update_settings(data['room'].except('name'))
    end
  end

  # =============
  #     USERS
  # =============
  
  def fetch_user_challenges(data)
    set_room
    battle = Battle.find(data["battle_id"])
    user = User.find(data["user_id"])

    FetchCompletedChallengesJob.perform_later(
      user_id: user.id,
      all_pages: false
    )
  end

  def get_room_players
    set_room
    set_current_user
    @room.broadcast_all_users(private_to_user_id: @current_user.id)
  end
  
  private

  def set_room
    @room = Room.find(params[:room_id]) if params[:room_id]
  end

  def set_current_user
    @current_user = User.find(params[:user_id])
  end
end
