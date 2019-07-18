json.extract!(
  user,
  :id,
  :username,
  :name,
  :last_fetched_at
)

json.invite_status user.invite_status
json.moderator user.moderator?(user.room)
