# # ============================
# # USERS

# trouni = User.find_or_create_by!(
#   username: "trouni",
#   password: "secret",
#   email: 'trouni@kesseo.com',
#   admin: true
# )

trouni = User.find_by(username: 'trouni')

# ============================
# Rooms & RoomUsers

# room = Room.find_or_create_by!(name: "Codewars SpeedBattles tutorial", moderator: trouni)
# room = Room.find_or_create_by!(name: "Le Wagon Tokyo 252", moderator: trouni)
# autonomous_room = Room.find_or_create_by!(name: "Autonomous Test Room", moderator: trouni)
# autonomous_room.update_settings(autonomous: true)

# Public rooms
public_rooms = [
  {
    name: "Ruby Beginners (8 kyu)",
    katas: {
      ranks: [-8]
    },
    languages: ['ruby'],
    max_users: 20,
    autonomous: true,
    time_limit: 5 * 60,
  },
  {
    name: "Ruby Beginners (7 kyu)",
    katas: {
      ranks: [-7]
    },
    languages: ['ruby'],
    max_users: 20,
    autonomous: true,
    time_limit: 10 * 60,
  },
  {
    name: "Ruby Intermediate (6 kyu)",
    katas: {
      ranks: [-6]
    },
    languages: ['ruby'],
    max_users: 20,
    autonomous: true,
    time_limit: 15 * 60,
  },
]

public_rooms.each do |room_hash|
  room = Room.find_or_create_by!(name: room_hash[:name], moderator: trouni, private: false)
  room.update_settings(room_hash.except(:name))
end