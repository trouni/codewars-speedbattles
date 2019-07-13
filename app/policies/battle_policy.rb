class BattlePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    true
  end

  def create?
    user == record.room.moderator
  end

  def update?
    user == record.room.moderator
  end

  def destroy?
    user == record.room.moderator
  end

  def invite_user?
    user == record.room.moderator
  end

  def invite_all?
    invite_user?
  end

  def invite_survivors?
    invite_user?
  end
end
