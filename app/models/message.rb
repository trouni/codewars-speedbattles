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
  belongs_to :user, required: false
  belongs_to :chat
  has_one :room, through: :chat
  validates :content, presence: true, allow_blank: false
  after_create_commit :broadcast

  def api_expose
    {
      id: id,
      content: content,
      created_at: created_at,
      author: {
        username: user&.username,
        name: user&.name,
        rank: user&.rank,
      }
    }
  end

  def broadcast
    return if room.inactive?

    ActionCable.server.broadcast(
      "room_#{room.id}",
      subchannel: "chat",
      payload: api_expose,
      roomId: room.id
    )
  end
end
