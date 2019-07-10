class Room < ApplicationRecord
  belongs_to :master, class_name: "User"
  has_many :room_users, dependent: :destroy
  has_many :users, through: :room_users
  has_many :battles
end
