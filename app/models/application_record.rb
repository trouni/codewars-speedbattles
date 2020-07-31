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

  def set_next_jid(jid, scope: "default")
    next_jid = settings(:base).next_jid
    next_jid[scope] = jid
    settings(:base).update(next_jid: next_jid)
  end
end
