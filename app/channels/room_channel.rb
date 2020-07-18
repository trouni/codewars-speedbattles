class RoomChannel < ApplicationCable::Channel
  include CodewarsHelper

  def subscribed
    set_room
    set_current_user
    # Disconnect from all other rooms
    ActionCable.server.remote_connections.where(current_user: @current_user).disconnect
    stop_all_streams
    # Subscribe to current room
    RoomUser.where(user: @current_user).destroy_all
    room_user = RoomUser.create(room: @room, user: @current_user)
    stream_from "room_#{@room.id}"
    stream_from "user_#{@current_user.id}"
    # Send initial data to user
    @current_user.broadcast_settings
    @room.broadcast_settings(private_to_user_id: @current_user.id)
    @room.broadcast_users
    @room.broadcast_messages(private_to_user_id: @current_user.id)
    @room.broadcast_active_battle(private_to_user_id: @current_user.id)
    # @room.broadcast_leaderboard

    # Invite to battle if autonomous room
    @room.active_battle.invitation(user: @current_user, action: "invite") if @room.settings(:base).autonomous
  end

  def unsubscribed
    set_room
    set_current_user
    stop_all_streams
    RoomUser.find_by(room: @room, user: @current_user).destroy
    # RoomUser.where(user: @current_user).destroy_all
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
    @room.settings(:base).update(auto_invite: data['auto_invite'])
    battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    battle.time_limit = data["time_limit"] if data["time_limit"]&.positive?
    battle.challenge_language = data['language']
    kata = Kata.find_by(codewars_id: data['challenge_id']) || Kata.find_by(slug: data['challenge_id'])
    kata ? battle.update(kata: kata) : @room.broadcast_active_battle
  end

  def create_random_battle(data)
    set_room
    kata_options = data['kata'].transform_keys(&:to_sym)
    @room.settings(:base).update(katas: kata_options.except(:language), auto_invite: data['auto_invite'])
    battle = Battle.new(
      room: @room,
      end_time: nil,
      challenge_language: kata_options[:language],
      kata: @room.random_kata(**kata_options),
      time_limit: data['time_limit'],
    )
    
    # Broadcast older battle if save failed
    @room.broadcast_active_battle unless battle.save
  end

  def update_battle(data)
    set_room
    battle = Battle.find(data["battle_id"])
    case data["battle_action"]
    when "start" then StartBattle.perform_now(battle, countdown: data["countdown"].to_i)
    when "end"
      end_at = battle.time_limit&.positive? ? [battle.start_time + battle.time_limit.seconds, Time.now].min : Time.now
      battle.terminate(end_at: end_at)
    when "ended-by-user"
      battle = @room.active_battle
      battle.time_limit = (Time.now - battle.start_time + 15.seconds).round
      @room.broadcast(subchannel: "battles", payload: { action: "active", battle: battle.api_expose })
    when "update" then battle.update(data["battle"])
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
    auto_start_battle if @room.settings(:base).autonomous
  end

  # =============
  #     SETTINGS
  # =============

  def update_user_settings(data)
    if data['user']
      set_current_user
      @current_user.update(name: data['user']['name'])
      @current_user.settings(:base).update(data['user'].except('name'))
    end
    @current_user.broadcast_settings
  end

  def update_room_settings(data)
    if data['room']
      set_room
      @room.update(name: data['room']['name'])
      @room.settings(:base).update(data['room'].except('name'))
    end
    @room.broadcast_settings
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
    @room.broadcast_to_moderator(subchannel: "logs", payload: "Fetching challenges for #{user.username}...")
  end

  def resubscribe
    set_room
    set_current_user
    RoomUser.find_or_create_by(room: @room, user: @current_user)
    @room.broadcast_to_moderator(subchannel: "logs", payload: "Re-subscribed #{@current_user.username}...")
  end

  def get_room_players
    set_room
    set_current_user
    @room.broadcast_players(private_to_user_id: @current_user.id)
  end

  # def get_leaderboard
  #   set_room
  #   @room.broadcast_leaderboard
  # end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_current_user
    @current_user = User.find(params[:user_id])
  end

  def auto_start_battle(countdown: 120)
    set_room
    if @room.active_battle.can_start?
      StartBattle.perform_now(@room.active_battle, countdown)
    else
      CancelStartBattle.perform_now(@room.active_battle)
    end
  end
end
