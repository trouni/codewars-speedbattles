# == Schema Information
#
# Table name: rooms
#
#  id         :bigint           not null, primary key
#  name       :string
#  master_id  :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Room < ApplicationRecord
  belongs_to :master, class_name: "User"
  has_many :room_users, dependent: :destroy
  has_many :users, through: :room_users
  has_many :battles
end
