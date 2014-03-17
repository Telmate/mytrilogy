# Utility file for migration that are all MySQL source
module Mytrilogy

class MysqlMigrations

  class << self
    attr_accessor :lol_dba_mode
  end

  #
  # mode can be :up or :down
  #
  def self.migration_for_file(ruby_file_name, mode = nil)
    sqlfile = ruby_file_name[/(.*)\.rb$/,1] + ".sql"
    migration_sql_file(sqlfile, mode)
  end

  #
  #
  #
  def self.migration_sql_file(sqlfile, mode = nil)
    case mode
      when :up, :down
        sqlfile = sqlfile[/(.*)\.sql$/,1] + "_#{mode}.sql"
    end
    puts "Running: #{File.basename(sqlfile)}"
    if lol_dba_mode
      puts `cat #{sqlfile} >> #{LolDba::Writer.path} 2>&1`
      return
    end
    raise "Missing mysql command line client." if `which mysql`.empty?
    config = ActiveRecord::Base.configurations[Rails.env]
    mysql_config_opts = "-h #{config['host']} -u #{config['username']} -p#{config['password']} #{config['database']}"

    tmp = Tempfile.new("mytrilogy")
    open(tmp.path, "w") { |tio|
      tio.write filter_file(sqlfile)
    }

    puts `mysql --show-warnings=true #{mysql_config_opts} < #{tmp.path} 2>&1`

    if $? == 0
      puts "Completed no errors."
    else
      raise "Problem with sql file."
    end
  end

  def self.filter_file(sqlfile)
    io = open(sqlfile, 'r')
    buf = []
    if ! io.grep(/-- start rails migration/).empty?
      io.seek 0
      takeline = false
      io.each_line { |line|
        if line['-- start rails migration']
          takeline = true
        elsif line['-- end rails migration']
          takeline = false
        elsif takeline
          buf << line
        end
      }
    else
      # No filtering...
      io.seek 0
      buf << io.read
    end
    buf.join ""
  end

end

end