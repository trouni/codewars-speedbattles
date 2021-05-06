# == Schema Information
#
# Table name: settings
#
#  id          :integer          not null, primary key
#  target_type :string           not null
#  value       :text
#  var         :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#  target_id   :integer          not null
#
class BaseSettingObject < RailsSettings::SettingObject
  after_commit :broadcast

  def broadcast
    target.broadcast_settings
  end
end
