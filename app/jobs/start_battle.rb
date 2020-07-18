class StartBattle < ApplicationJob
  queue_as :default

  def perform(battle, countdown = 0)
    battle.start(countdown: countdown)
  end
end
