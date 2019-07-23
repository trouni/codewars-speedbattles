class RoomPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    user = record.moderator
  end

  def leaderboard?
    show?
  end
end
