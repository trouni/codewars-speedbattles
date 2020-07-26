class EndBattle < ApplicationJob
  queue_as :critical

  def perform(battle_id:, end_at: nil, force: false)
    battle = Battle.find(battle_id)
    return unless latest_job_for?(battle.room) || force

    end_at ||= battle.start_time + battle.time_limit.seconds if battle.time_limit?
    battle.terminate(end_at: end_at)
  end
end
