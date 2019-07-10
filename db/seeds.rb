CODEWARS_USERNAMES = %w[Uraza glebec Leig TinoC lwoo1999] # jnicol MiraliN EnigmaWasp asltyn brubru777 NyxTo xSmallDeadGuyx gabrielsiedler mlabrum richardhsu]

Battle.destroy_all
Room.destroy_all
User.destroy_all

# ============================
# USERS

User.create!(
  email: "trouni@me.com",
  username: "trouni",
  password: "secret",
  admin: true
)

CODEWARS_USERNAMES.each do |username|
  User.create!(
    email: "#{username.downcase}@me.com",
    username: username,
    password: "secret"
  )
end

# ============================
# Rooms & RoomUsers

room = Room.create!(name: "Le Wagon - Tokyo 252", master: User.first)
User.all.each do |user|
  RoomUser.create!(room: room, user: user, player: true)
end
