json.extract! @battle, :id, :room_id, :max_survivors, :time_limit, :start_time, :end_time

json.challenge @battle, partial: 'api/v1/battles/challenge', as: :battle
