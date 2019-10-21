class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :username, :name, :last_fetched_at

  attribute :invite_status do |user|
    user.invite_status(user.active_battle)
  end

  attribute :completed_at do |user|
    user.active_battle&.completed_challenge_at(user)
  end

  attribute :stats, if: proc { |_record, params| _record.room && params[:stats] } do |user|
    {
      battles_survived: user.survived(user.room).size,
      battles_fought: user.battles.for_room(user.room).size,
      victories: user.room.victories(user).size,
      total_score: user.room.total_score(user)
    }
  end
end
