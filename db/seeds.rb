CODEWARS_USERNAMES = %w[gabrielsiedler mlabrum richardhsu] # Uraza glebec Leig TinoC lwoo1999 jnicol MiraliN EnigmaWasp asltyn brubru777 NyxTo xSmallDeadGuyx gabrielsiedler mlabrum richardhsu

Battle.destroy_all
Room.destroy_all
User.destroy_all

# # ============================
# # USERS

User.create!(
  username: "trouni",
  password: "secret",
  email: 'trouni@kesseo.com',
  admin: true
)

User.create!(
  username: "moderator",
  password: "supersecret",
  email: 'speedbattles@kesseo.com',
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

room = Room.create!(name: "Codewars SpeedBattles tutorial", moderator: User.find_by(username: 'moderator'))
room = Room.create!(name: "Le Wagon Tokyo 279", moderator: User.find_by(username: 'moderator'))
autonomous_room = Room.create!(name: "Autonomous Test Room", moderator: User.find_by(username: 'trouni'))
autonomous_room.settings(:base).update(autonomous: true)
# User.all.each do |user|
#   RoomUser.create!(room: room, user: user)
# end
