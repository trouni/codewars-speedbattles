class BroadcastInitialInfoJob < ApplicationJob
  include Cancelerizer
  queue_as :default

  DELAY = 3.seconds

  class << self
    def process(room_id)
      # cancel_perform(room_id)
      # set(wait: DELAY).perform_later(room_id)
      perform_now(room_id)
    end
  end

  def perform(room_id)
    room = Room.find(room_id)
    room.broadcast_users
    room.broadcast_messages
    room.broadcast_active_battle
  end
end
