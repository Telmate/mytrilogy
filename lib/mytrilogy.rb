require "mytrilogy/version"
require "mytrilogy/mysql_migrations"

if defined?(Rails)
  require "activerecord_storedprocedure"
  require "mytrilogy/railtie.rb" if defined?(Rails::Railtie)
end

module Mytrilogy
  def self.get_db_config(name)
    if ActiveRecord::Base.configurations.respond_to?(:find_db_config)
      ActiveRecord::Base.configurations.find_db_config(name).configuration_hash.with_indifferent_access
    else
      ActiveRecord::Base.configurations[name]
    end
  end
end