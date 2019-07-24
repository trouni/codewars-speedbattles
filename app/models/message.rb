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
  validates :content, presence: true, allow_blank: false
  after_create :broadcast_message

  def api_expose
    {
      id: id,
      content: content,
      created_at: created_at,
      author: user.api_expose
    }
  end

  def self.create_announcement(content, chat_id)
    return Message.create(
      user: User.find_or_create_bot,
      content: content,
      chat: Chat.find(chat_id)
    )
  end

  def broadcast_message
    ActionCable.server.broadcast(
      "chat_#{chat.id}",
      api_expose
    )
  end
end
