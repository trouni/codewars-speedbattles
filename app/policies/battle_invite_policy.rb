class BattleInvitePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?
    record.battle.room.moderator == user
  end

  def update?
    record.battle.room.moderator == user || record.battle.room.moderator == record.player
  end

  def destroy?
    record.battle.room.moderator == user || record.battle.room.moderator == record.player
  end

  def invite_all?
    true
  end

  def invite_user?
    create?
  end

  def uninvite_user?
    destroy?
  end
end
