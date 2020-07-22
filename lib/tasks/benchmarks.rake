require 'benchmark'

namespace :bm do
  desc "Benchmark for single SQL query to broadcast current_users"
  task :users_info, [:room_id, :n] => :environment do |task, args|
    n = args[:n].to_i || 200
    room = args[:room_id] ? Room.find(args[:room_id]) : Room.last
    Benchmark.bm do |x|
      old = x.report(:original) { n.times do; room.old_users_info; end }
      new = x.report(:new) { n.times do; room.users_info(:current_users); end }
    end
  end

  desc "Benchmark for single SQL query to broadcast players"
  task :players_info, [:room_id, :n] => :environment do |task, args|
    n = args[:n].to_i || 200
    room = args[:room_id] ? Room.find(args[:room_id]) : Room.last
    Benchmark.bm do |x|
      old = x.report(:original) { n.times do; room.old_players_info; end }
      new = x.report(:new) { n.times do; room.users_info(:current_players); end }
    end
  end
end
