class CancelStartBattle < ApplicationJob
  queue_as :default

  def perform(battle)
    return if Time.now >= battle.start_time

    battle.room.set_timer(0, '')
    battle.update(start_time: nil)
  end
end
