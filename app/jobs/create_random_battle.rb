class CreateRandomBattle < RoomFlowJob
  queue_as :default

  def perform(room_id:, language: nil, time_limit: nil, kata_options: nil, force: false)
    battle = Battle.find_or_initialize_by(room: @room, end_time: nil)
    return unless battle.new_record?

    kata_options ||= @room.settings(:base).katas
    language ||= @room.settings(:base).languages.sample
    battle.assign_attributes(
      challenge_language: language,
      kata: @room.random_kata(**kata_options, language: language),
      time_limit: time_limit || @room.settings(:base).time_limit
    )
    
    # Broadcast older battle if save failed
    @room.broadcast_active_battle unless battle.save
  end
end
