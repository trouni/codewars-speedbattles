class EndBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, end_at: nil, force: false)
    battle = Battle.find(battle_id)
    return unless latest_job_for?(battle.room) || force

    expected_end_time = battle&.start_time + battle&.time_limit.seconds
    end_at ||= expected_end_time if expected_end_time < Time.now
    battle.terminate(end_at: end_at)
    # battle.room.clear_next_event!(only: 'end-battle')
  end
end
