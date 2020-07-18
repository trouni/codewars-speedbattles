class CancelStartBattle < ApplicationJob
  queue_as :default

  def perform(battle)
    battle.update(start_time: nil) unless Time.now >= battle.start_time
  end
end
