require "mytrilogy/version"
require "mytrilogy/mysql_migrations"

if defined?(Rails)
  require "activerecord_storedprocedure"
  require "mytrilogy/railtie.rb"
end

