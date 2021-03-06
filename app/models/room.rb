# == Schema Information
#
# Table name: rooms
#
#  id           :bigint           not null, primary key
#  name         :string
#  private      :boolean          default(TRUE)
#  show_stats   :boolean          default(TRUE)
#  sound        :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  moderator_id :bigint
#

class Room < ApplicationRecord
  belongs_to :moderator, class_name: "User"
  has_many :room_users, dependent: :destroy
  has_many :users, through: :room_users
  has_many :battles, dependent: :destroy
  has_many :players, through: :battles
  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat
  validates :name, presence: true

  after_create_commit :create_chat
  after_update :announce_new_name, if: :saved_change_to_name?

  has_settings class_name: 'BaseSettingObject' do |s|
    s.key :base, defaults: {
      sound: true,
      classification: 'TOP SECRET',
      katas: {
        ranks: [-8, -7, -6, -5, -4, -3, -2, -1],
        min_votes: 50,
        min_satisfaction: 90,
        ignore_higher_rank_users: false,
      },
      max_users: 0,
      min_users: 2,
      languages: ['ruby'],
      auto_invite: false,
      autonomous: false,
      voice_chat_url: nil,
      time_limit: 10 * 60,
      # Array of languages for future support of multi-lang rooms
      moderators: [],
      next_event: {
        at: Time.now,
        type: nil,
      },
      next_jid: Hash.new,
      updated_at: nil
    }
  end

  def settings_hash
    return {
      id: id,
      name: name,
      users_count: room_users.count,
      max_users: settings(:base).max_users,
      sound: settings(:base).sound,
      voice_chat_url: settings(:base).voice_chat_url,
      classification: settings(:base).classification,
      katas: settings(:base).katas,
      codewars_langs: Kata.languages,
      languages: settings(:base).languages,
      autonomous: autonomous?,
      next_event: {
        timer: time_until_next_event,
        type: settings(:base).next_event[:type],
      },
      updated_at: settings(:base).updated_at
    }
  end

  def inactive?
    room_users.empty?
  end

  def autonomous?
    settings(:base).autonomous
  end

  def min_users
    settings(:base).min_users
  end

  def auto_schedule_new_battle?
    autonomous? && users.count >= min_users && !unfinished_battle? && !next_event?
  end

  def next_event
    settings(:base).next_event
  end

  def time_until_next_event
    return unless settings(:base).next_event[:at]

    time_left = settings(:base).next_event[:at] - Time.now
    return time_left if time_left.positive?
  end
  alias_method :next_event?, :time_until_next_event

  def unfinished_battle
    Battle.includes(:room).joins(:room).find_by(room: self, end_time: nil)
  end

  def unfinished_battle?
    unfinished_battle.present?
  end

  def active_battle
    return unfinished_battle || last_battle
  end

  def active_battle?
    active_battle.present?
  end

  def finished_battles
    Battle.includes(:room).joins(:room).where(room_id: id).where.not(end_time: nil).order(end_time: :desc)
  end

  def last_battle
    finished_battles.first
  end

  def available_katas(language: nil, ranks: [], min_votes: nil, min_satisfaction: nil, ignore_higher_rank_users: true, excluded_users: [])
    selected_users = users.reject { |user| excluded_users.include?(user) }
    selected_users.reject! { |user| user.rank > ranks.max } if ignore_higher_rank_users && ranks.any?
    selection = Kata.where.not(id: Kata.joins(:users).where(users: { id: selected_users }).distinct)
    selection = selection.where.not(satisfaction_rating: nil)
    selection = selection.where('total_votes > ?', min_votes) if min_votes
    selection = selection.where('satisfaction_rating > ?', min_satisfaction) if min_satisfaction
    selection = selection.where(rank: ranks) if ranks.any?
    selection = selection.where("? = ANY (languages)", language) if language
    selection.order(satisfaction_rating: :desc)
  end

  def random_kata(**options)
    available_katas(options).sample
  end

  def broadcast(subchannel: "logs", payload: nil, private_to_user_id: nil)
    # Don't broadcast to the room if it is empty,
    # but can still broadcast privately to spectators.
    return if inactive? && private_to_user_id.nil?

    ActionCable.server.broadcast(
      private_to_user_id ? "user_#{private_to_user_id}" : "room_#{id}",
      subchannel: subchannel,
      payload: payload,
      roomId: id,
      # broadcasted_by: caller[0..2]
    )
  end

  def broadcast_settings(private_to_user_id: nil)
    broadcast({
      subchannel: "settings",
      payload: {
        action: "room",
        settings: settings_hash
      },
      private_to_user_id: private_to_user_id
    })
  end

  def broadcast_users(private_to_user_id: nil)
    broadcast(
      subchannel: "users",
      payload: {
        action: "all",
        users: User.info(self, :current_users_and_players).as_json
      },
      private_to_user_id: private_to_user_id
    )
  end

  def announce(channel, message, **options)
    case channel
    when :chat then chat.create_announcement(message)
    when :voice then broadcast_voice(message, options)
    end
  end

  def broadcast_voice(message, options)
    broadcast(
      subchannel: "action",
      payload: {
        action: "voice-announce",
        message: message,
        options: options,
      }
    )
    chat.create_announcement(options[:chat_msg] == true ? message : options[:chat_msg]) if options[:chat_msg]
  end

  def broadcast_messages(private_to_user_id: nil)
    broadcast(
      subchannel: "chat",
      payload: {
        action: "all",
        messages: messages.includes(:user).order(created_at: :desc).limit(100).map(&:api_expose),
        authors: chat.users.select(:id, :username, :name)
      },
      private_to_user_id: private_to_user_id
    )
  end

  # Broadcast all room players (for offline players stats)
  def broadcast_all_users(private_to_user_id: nil)
    broadcast(
      subchannel: "users",
      payload: {
        action: "room-players",
        users: User.info(self, :all_users_and_players)
      },
      private_to_user_id: private_to_user_id
    )
  end

  def broadcast_action(action:, data: nil)
    broadcast(subchannel: "action", payload: { action: action, data: data })
  end

  def broadcast_user(action: "add", user:)
    broadcast(subchannel: "users", payload: { action: action, user: user.info(self) })
  end

  def broadcast_active_battle(private_to_user_id: nil)
    active_battle&.check_if_time_over
    broadcast(subchannel: "battles", payload: { action: "active", battle: active_battle&.api_expose }, private_to_user_id: private_to_user_id)
  end

  def set_next_event(at:, type: nil)
    update_settings(next_event: { at: at, type: type })
  end

  def set_timer(delay, type = nil)
    # delay must be a duration (e.g. seconds, minutes, etc.)
    set_next_event(at: Time.now + delay, type: type)
  end

  private

  def create_chat
    Chat.create!(room: self, name: name)
  end

  def announce_new_name
    announce(:chat, "War room renamed to <strong>#{name}</strong>.")
  end
end
