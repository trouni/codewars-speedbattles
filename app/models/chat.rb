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

  # def broadcast_announcement(content)
  #   Message.create_announcement(content, id)
  # end
end
