json.chat_id @chat.id

json.messages @chat.messages do |message|
  json.partial! message
end
