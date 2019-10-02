class RoomChannel < ApplicationCable::Channel
  include CodewarsHelper

  def subscribed
    set_room
    set_current_user
    room_user = RoomUser.find_or_create_by(room: @room, user: @current_user)
    stream_from "room_#{@room.id}"
    stream_from "room_#{@room.id}_moderator" if @current_user == @room.moderator
    # room_user.broadcast("add")
  end

  def unsubscribed
    set_room
    set_current_user
    room_user = RoomUser.find_by(room: @room, user: @current_user).destroy
    # room_user.broadcast("remove")
    stop_all_streams
    # broadcast_users @room
  end

  def receive(data)
  end

  # =============
  #     CHAT
  # =============

  def create_message(data)
    set_room
    set_current_user
    Message.create(user_id: @current_user.id, chat_id: @room.chat.id, content: data["message"])
  end

  # =============
  #    BATTLES
  # =============

  def create_battle(data)
    set_room
    battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    challenge = fetch_kata_info(data["challenge_id"])
    battle.update(challenge)
  end

  def update_battle(data)
    battle = Battle.find(data["battle_id"])
    case data["battle_action"]
    when "start"
      countdown = data["countdown"].to_i
      @room.broadcast_action(action: 'start-countdown', data: { countdown: countdown })
      battle.update(start_time: DateTime.now + countdown.seconds) unless battle.start_time
      # battle.launch(countdown)
      battle.battle_invites.where(confirmed: false).destroy_all
    when "end"
      battle.update(end_time: DateTime.now) unless battle.end_time
      battle.defeated_players.each(&:async_fetch_codewars_info)
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

    # Don't Fetch challenges if already completed or fetched within last 5 seconds
    return if battle.survived?(user) || user.last_fetched_at > (DateTime.now - 5.seconds)

    FetchCompletedChallengesJob.perform_later(
      user_id: data["user_id"],
      battle_id: data["battle_id"],
      all_pages: false
    )
    @room.broadcast_to_moderator(subchannel: "logs", payload: "Fetching challenges for #{user.username}...")
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_current_user
    @current_user = User.find(params[:user_id])
  end
end
