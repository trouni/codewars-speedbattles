namespace :users do
  desc "Display users who registered in the last 24 hours"
  task last_registered: :environment do
    users = User.where('created_at > ?', Time.now - 1.day).order(:created_at)
    puts "#{users.count} users created today:"
    users.each_with_index do |user, index|
      output = "#{index + 1} - #{user.username}"
      output += " (#{user.name})" if user.name
      output += " - #{user.email}" if user.email
      output += " - #{user.settings(:base).hljs_lang}" if user.settings(:base).hljs_lang
      output += user.connected_webhook? ? " - Webhook✅" : " - Webhook❌"
      
      puts output
    end
  end
end
