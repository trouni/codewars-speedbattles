class RoomPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(private: false)
      end
    end
  end

  def show?
    true
  end

  def new?
    create?
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
