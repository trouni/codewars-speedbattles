CODEWARS_USERNAMES = %w[gabrielsiedler mlabrum richardhsu] # Uraza glebec Leig TinoC lwoo1999 jnicol MiraliN EnigmaWasp asltyn brubru777 NyxTo xSmallDeadGuyx gabrielsiedler mlabrum richardhsu

Battle.destroy_all
Room.destroy_all
User.destroy_all

# # ============================
# # USERS

User.create!(
  username: "trouni",
  password: "secret",
  admin: true
)

User.create!(
  username: "moderator",
  password: "supersecret",
  admin: true
)

# CODEWARS_USERNAMES.each do |username|
#   User.create!(
#     username: username,
#     password: "secret"
#   )
# end

# ============================
# Rooms & RoomUsers

room = Room.create!(name: "CodeWars SpeedBattles tutorial", moderator: User.find_by(username: 'moderator'))
room = Room.create!(name: "Le Wagon Tokyo 252", moderator: User.find_by(username: 'moderator'))
# User.all.each do |user|
#   RoomUser.create!(room: room, user: user)
# end
