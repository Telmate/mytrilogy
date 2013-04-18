# Utility file for migration that are all MySQL source
module Mytrilogy

class MysqlMigrations

  class << self
    attr_accessor :lol_dba_mode
  end

  def self.migration_for_file(ruby_file_name)
    sqlfile = ruby_file_name[/(.*)\.rb$/,1] + ".sql"
    migration_sql_file(sqlfile)
  end

  def self.migration_sql_file(sqlfile)
    puts "Running: #{File.basename(sqlfile)}"
    if lol_dba_mode
      puts `cat #{sqlfile} >> #{LolDba::Writer.path} 2>&1`
      return
    end
    raise "Missing mysql command line client." if `which mysql`.blank?
    config = ActiveRecord::Base.configurations[Rails.env]
    mysql_config_opts = "-h #{config['host']} -u #{config['username']} -p#{config['password']} #{config['database']}"
    puts `mysql --show-warnings=true #{mysql_config_opts} < #{sqlfile} 2>&1`
    if $? == 0
      puts "Completed no errors."
    else
      raise "Problem with sql file."
    end
  end


end

end