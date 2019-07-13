class BattleInvitePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?
    record.battle.room.moderator = user
  end

  def update?
    record.battle.room.moderator = user || record.player
  end

  def destroy?
    record.battle.room.moderator = user || record.player
  end
end
