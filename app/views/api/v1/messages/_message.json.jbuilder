# json.extract! message, :id, :content, :created_at
# json.author message.user, :id, :username, :name
json.merge! message.api_expose
