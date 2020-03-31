class RoomChannel < ApplicationCable::Channel
  include CodewarsHelper

  def subscribed
    set_room
    set_current_user
    room_user = RoomUser.find_or_create_by(room: @room, user: @current_user)
    stream_from "room_#{@room.id}"
    stream_from "room_#{@room.id}_moderator" if @current_user == @room.moderator
    # BroadcastInitialInfoJob.process(params[:room_id])
    @room.broadcast_users
    @room.broadcast_messages
    @room.broadcast_active_battle
    @room.broadcast_leaderboard
  end

  def unsubscribed
    set_room
    set_current_user
    room_user = RoomUser.find_by(room: @room, user: @current_user)
    room_user.destroy
    # room_user.broadcast("remove")
    stop_all_streams
    # broadcast_users @room
  end

  def trigger_event(data)
    set_room
    case data['event']
    when 'battle-has-begun'
      announcement = "<i class='fas fa-rocket mr-1'></i> The battle for <span class='chat-highlight'>#{@room.active_battle.challenge.name}</span> has begun!"
      @room.announce(:chat, announcement)
    end
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

  def create_battle(data)
    set_room
    battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    battle.time_limit = data["time_limit"]
    challenge = fetch_kata_info(data["challenge_id"])
    battle.update(challenge)
  end

  def update_battle(data)
    set_room
    battle = Battle.find(data["battle_id"])
    case data["battle_action"]
    when "start" then battle.start(countdown: data["countdown"].to_i)
    when "end"
      end_at = battle.time_limit ? [battle.start_time + battle.time_limit.seconds, Time.now].min : Time.now
      battle.terminate(end_at: end_at)
    when "ended-by-user" then battle.update(time_limit: (Time.now - battle.start_time + 15.seconds).round)
    when "update" then battle.update(data["battle"])
    end
  end

  def delete_battle(data)
    Battle.find(data["battle_id"]).destroy
  end

  def invitation(data)
    battle = Battle.find(data["battle_id"])
    user = User.find(data["user_id"]) if data["user_id"]
    battle.invitation(user: user, action: data["invite_action"])
  end

  # =============
  #     USERS
  # =============

  def fetch_user_challenges(data)
    set_room
    battle = Battle.find(data["battle_id"])
    user = User.find(data["user_id"])

    # # Don't Fetch challenges if already completed or fetched within last 5 seconds
    # return if user.survived?(battle) || (user.last_fetched_at || Time.now) > (Time.now - 5.seconds)

    FetchCompletedChallengesJob.perform_later(
      user_id: user.id,
      battle_id: battle.id,
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
    @room.broadcast_players
  end

  def get_leaderboard
    set_room
    @room.broadcast_leaderboard
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_current_user
    @current_user = User.find(params[:user_id])
  end
end
