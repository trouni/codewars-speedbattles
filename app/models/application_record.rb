class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.execute_sql(query, args = {})
    query = sanitize_sql([query, args])
    results = ActiveRecord::Base.connection.execute(query)
  
    if results.present?
      return results
    else
      return nil
    end
  end

  def update_settings(data = Hash.new)
    data[:updated_at] = Time.now
    settings(:base).update(data)
  end

  def set_next_jid(jid, scope: nil)
    scope ||= "default"
    next_jid = settings(:base).next_jid
    next_jid[scope] = jid
    update_settings(next_jid: next_jid)
  end
end
