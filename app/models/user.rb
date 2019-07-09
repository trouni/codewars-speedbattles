class User < ApplicationRecord
  has_many :room_users
  has_many :rooms, through: :room_users
  has_many :battle_players, foreign_key: 'player_id'
  has_many :battles, through: :battle_players
  has_many :battles_as_winner, class_name: 'Battle', foreign_key: 'winner_id'
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
