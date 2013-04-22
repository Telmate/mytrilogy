module ActiverecordStoredprocedure


  def self.included(base)
    base.extend(ClassMethods)
  end
    
    
  module ClassMethods
    
    # The stored procedure you call here should return columns compatable with your model
    def find_by_procedure(proc_name, *args)
      begin
        find_by_sql(procedure_sql_array(proc_name, *args))
      rescue ActiveRecord::StatementInvalid => arsi
        procedure_rescue_reflect(arsi)
      end
    end
    
    # call using exec with no result set
    def call_procedure(proc_name, *args)
      begin
        connection.execute(sanitize_sql(procedure_sql_array(proc_name, *args)))
      rescue ActiveRecord::StatementInvalid => arsi
        procedure_rescue_reflect(arsi)
      end
    end
    
  protected
    
    # construct mysql call + argument array
    def procedure_sql_array(proc_name, *args)
      # TODO - consider optimizing the parameter sanitizing
      ["CALL #{proc_name}(#{(['?'] * args.length).join(',')})", *args]
    end
    
    # arsi - ActiveRecord::StatementInvalid
    def procedure_rescue_reflect(arsi)
      # Reflect out errors like #ActiveRecord::RecordNotFound# xxx
      if (mm = /#([^#]+)#\s*/.match(arsi.message))
        msg = mm.post_match
        err_class = begin
              mm[1].constantize
            rescue
              msg = "##{mm[1]}# #{msg}"
              StandardError
            end
        raise err_class.new(msg)
      else
        raise arsi
      end
    end
    
    
  end
  
end
