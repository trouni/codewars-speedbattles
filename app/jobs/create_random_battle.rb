class CreateRandomBattle < ApplicationJob
  queue_as :default

  def perform(room:, language: nil, time_limit: nil, kata_options: nil)
    kata_options ||= room.settings(:base).katas
    battle = Battle.find_or_initialize_by(room: room, end_time: nil)
    battle.assign_attributes(
      challenge_language: language || room.settings(:base).languages.sample,
      kata: room.random_kata(**kata_options),
      time_limit: time_limit || room.settings(:base).time_limit
    )
    
    # Broadcast older battle if save failed
    room.broadcast_active_battle unless battle.save
    room.set_timer(0, '')
  end
end
