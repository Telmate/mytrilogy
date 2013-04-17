Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

# Override existing test task to prevent integrations
# from being run unless specifically asked for
remove_task 'db:test:prepare'
remove_task 'db:test:clone_structure'


namespace :db do
  namespace :test do

    desc "Check for pending migrations and load the test schema with mysql"
    task :prepare => 'db:test:purge' do
      config = current_config
      test_config = current_config(:config => ActiveRecord::Base.configurations['test'])
      mysql_config_opts = "-h #{config['host']} -u #{config['username']} -p#{config['password']} #{config['database']}"
      mysql_test_config_opts = "-h #{test_config['host']}  -u #{test_config['username']} -p#{test_config['password']} #{test_config['database']}"

      test_databases = {}
      ActiveRecord::Base.configurations.each { |key,val|
        if /test$/ =~ key
          dbn = val["database"]
          test_databases[dbn[/(.*)_test/,1]] = dbn
        end
      }
      dbname_rx = Regexp.new test_databases.keys.collect {|dbn| ["#{dbn}\\.", "`#{dbn}`\\."] }.flatten.join('|')
      #puts dbname_rx.source

      schema_source = `mysqldump --routines --no-data #{mysql_config_opts}`
      schema_source.gsub!(dbname_rx) { |mm|
        "`#{test_databases[mm.tr('`.','')]}`."
      }
      # Strip DEFINER=`root`@`localhost` parts
      schema_source.gsub!(/DEFINER=[^\s\*]+/, "")
      #puts schema_source

      IO.popen("mysql #{mysql_test_config_opts}", "w+") { |io|
        io.write schema_source
        io.close_write
        res = io.read
        if /ERROR/ =~ res
          puts res
        end
      }

      `mysqldump --no-create-info --no-create-db #{mysql_config_opts} schema_migrations | mysql #{mysql_test_config_opts}`

    end

    desc "Alias to mysql specific db:test:prepare"
    task :clone_structure => 'db:test:prepare' do
      # nothing else...
    end

  end

  namespace :mysql do

    # Example:
    # rake db:mysql:sql2rb IN=/tmp/somefile.sql OUT=db/migrate/20130319210111_some_sql.rb
    desc "Turn a mysql .sql file into a rails database migration"
    task :sql2rb => :environment do
      fin = ENV["IN"]
      fout = ENV["OUT"]
      raise "IN=file.sql OUT=file.rb required" if fin.blank? || fout.blank?
      require 'mytrilogy/mysql_transformer'
      mt = Mytrilogy::MysqlTransformer.new
      mt.strip_db_names << ActiveRecord::Base.configurations[Rails.env]['database']
      bytes = mt.dump2migration(fin, fout)
      puts "Completed, #{bytes} bytes written."
    end

    # Example:
    # rake db:mysql:dump2rb OUT=db/migrate/20130214210111_copy_schema.rb
    desc "Turn a live mysqldump file into rails database migration"
    task :dump2rb => :environment do
      fout = ENV["OUT"]
      raise "OUT=file.rb required" if fout.blank?
      require 'mytrilogy/mysql_transformer'
      mt = Mytrilogy::MysqlTransformer.new
      config = ActiveRecord::Base.configurations[Rails.env]
      mt.strip_db_names << config['database']
      mysql_config_opts = "-h #{config['host']} -u #{config['username']} -p#{config['password']} #{config['database']}"
      tmpname = "/tmp/dump#{Time.now.to_i}.sql"
      puts `mysqldump --routines --no-data --ignore-table=#{config['database']}.schema_migrations #{mysql_config_opts} > #{tmpname}`
      bytes = mt.dump2migration(tmpname, fout)
      puts "Completed, #{bytes} bytes written."
    end

  end

end