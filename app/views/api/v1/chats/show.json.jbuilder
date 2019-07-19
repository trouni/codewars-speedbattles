json.chat_id @chat.id

json.messages @messages.map(&:api_expose) # do |message|
#   json.partial! message
# end
