module ActiverecordStoredprocedure


  def self.included(base)
    base.extend(ClassMethods)
  end
    
    
  module ClassMethods
    
    # The stored procedure you call here should return columns compatable with your model
    def find_by_procedure(proc_name, *args)
      begin
        # TODO - consider optimizing the parameter sanitzing
        find_by_sql(["CALL #{proc_name}(#{(['?'] * args.length).join(',')})", *args])
      rescue ActiveRecord::StatementInvalid => arsi
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
  
end
