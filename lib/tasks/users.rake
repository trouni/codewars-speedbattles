namespace :users do
  desc "Display users who registered in the last 24 hours"
  task last_registered: :environment do
    users = User.where('created_at > ?', Time.now - 1.day).order(:created_at)
    puts "#{users.count} users created today:"
    users.each_with_index do |user, index|
      output = "#{index + 1} - #{user.username}"
      output += " (#{user.name})" unless user.name&.empty?
      output += " - #{user.email}" unless user.email&.empty?
      puts output
    end
  end

  desc "Add all users from latest 24 hours to the latest battle as confirmed players"
  task add_to_last_battle: :environment do

  end
end
