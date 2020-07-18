class CreateRandomBattle < ApplicationJob
  queue_as :default

  def perform(room, kata_options = nil)
    kata_options ||= room.settings(:base).katas
    Battle.create(
      room: room,
      end_time: nil,
      challenge_language: room.settings(:base).languages.sample,
      kata: room.random_kata(**kata_options),
      time_limit: room.settings(:base).time_limit
    )
  end
end
