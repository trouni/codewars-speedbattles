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

  def invitation?
    true
  end

  def invite_user?
    user == record.battle.room.moderator
  end

  def uninvite_user?
    user == record.battle.room.moderator || user == record.player
  end

  def confirm_user?
    user == record.battle.room.moderator || user == record.player
  end

  def invite_all?
    invite_user?
  end

  def invite_survivors?
    invite_user?
  end
end
