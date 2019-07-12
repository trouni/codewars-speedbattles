json.array! @rooms do |room|
  json.extract! room, :id, :name
end
