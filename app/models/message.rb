# == Schema Information
#
# Table name: messages
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  chat_id    :bigint
#  content    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat
  has_one :room, through: :chat
  validates :content, presence: true, allow_blank: false
  after_create_commit :broadcast

  def api_expose
    {
      id: id,
      content: content,
      created_at: created_at,
      author: user ? user&.api_expose : User.find_by(username: bot)&.api_expose
    }
  end

  # def self.create_announcement(content, chat_id)
  #   return Message.create(
  #     user: User.find_or_create_bot,
  #     content: content,
  #     chat: Chat.find(chat_id)
  #   )
  # end

  def broadcast
    ActionCable.server.broadcast(
      "room_#{room.id}",
      subchannel: "chat",
      payload: api_expose
    )
  end
end
