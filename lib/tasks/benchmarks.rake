require 'benchmark'

namespace :bm do
  desc "Benchmark for single SQL query to broadcast current_users"
  task :users_info, [:room_id, :n] => :environment do |task, args|
    n = args[:n].to_i || 200
    room = args[:room_id] ? Room.find(args[:room_id]) : Room.last
    Benchmark.bm do |x|
      x.report(:original) { n.times do; room.old_users_info; end }
      x.report(:new) { n.times do; User.info(room, group: :current_users); end }
    end
  end

  desc "Benchmark for single SQL query to broadcast players"
  task :players_info, [:room_id, :n] => :environment do |task, args|
    n = args[:n].to_i || 200
    room = args[:room_id] ? Room.find(args[:room_id]) : Room.last
    Benchmark.bm do |x|
      x.report(:original) { n.times do; room.old_players_info; end }
      x.report(:new) { n.times do; User.info(room, group: :all_users_and_players); end }
    end
  end
end
