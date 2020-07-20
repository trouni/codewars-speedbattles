class StartBattle < ApplicationJob
  queue_as :critical

  def perform(battle, countdown = 0)
    battle.room.set_timer(countdown, 'start-battle')
    battle.start(countdown: countdown)
  end
end
