class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def execute_sql(sql, args = {})
    results = ActiveRecord::Base.connection.execute(sql, args)
  
    if results.present?
      return results
    else
      return nil
    end
  end
end
