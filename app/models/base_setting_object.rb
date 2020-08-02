class BaseSettingObject < RailsSettings::SettingObject
  after_commit :broadcast

  def broadcast
    target.broadcast_settings
  end
end