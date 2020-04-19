# == Schema Information
#
# Table name: chats
#
#  id         :bigint           not null, primary key
#  name       :string
#  room_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Chat < ApplicationRecord
  belongs_to :room
  has_many :messages, dependent: :destroy
  has_many :users, -> { distinct }, through: :messages
  after_create :welcome_message

  # def broadcast_announcement(content)
  #   Message.create_announcement(content, id)
  # end

  def create_announcement(content)
    Message.create(
      user: nil,
      content: content,
      chat: self
    )
  end

  private

  def welcome_message
    create_announcement("War room <strong>#{room.name}</strong> has been created.")
  end
end
