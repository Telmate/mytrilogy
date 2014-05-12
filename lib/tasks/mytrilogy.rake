Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

# The current_config method is not defined in earlier versions of ActiveRecord::Tasks::DatabaseTasks
# See: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/tasks/database_tasks.rb#L57
unless self.respond_to?(:current_config)

  def current_config(options = {})
    options.reverse_merge! :env => Rails.env
    if options.has_key?(:config)
      @current_config = options[:config]
    else
      @current_config ||= if ENV['DATABASE_URL']
                            ConnectionAdapters::ConnectionSpecification::Resolver.new(ENV["DATABASE_URL"], {}).spec.config.stringify_keys
                          else
                            ActiveRecord::Base.configurations[options[:env]]
                          end
    end
  end

end


if Rails.version.to_i > 2
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
        ActiveRecord::Base.configurations.each do |key,val|
          if /test$/ =~ key
            dbn = val["database"]
            test_databases[dbn[/(.*)_test/,1]] = dbn
          end
        end
        dbname_rx = Regexp.new test_databases.keys.collect {|dbn| ["#{dbn}\\.", "`#{dbn}`\\."] }.flatten.join('|')
        #puts dbname_rx.source

        schema_source = `mysqldump --routines --no-data #{mysql_config_opts}`
        schema_source.gsub!(dbname_rx) { |mm| "`#{test_databases[mm.tr('`.','')]}`." }
        # Strip DEFINER=`root`@`localhost` parts
        schema_source.gsub!(/DEFINER=[^\s\*]+/, "")
        #puts schema_source

        IO.popen("mysql #{mysql_test_config_opts}", "w+") do |io|
          io.write schema_source
          io.close_write
          res = io.read
          if /ERROR/ =~ res
            puts res
          end
        end

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

      desc "Convert /db/migration_sql scripts back into migration rb files"
      task :migrate_sql2rb => :environment do

        require 'mytrilogy/mysql_transformer'
        mt = Mytrilogy::MysqlTransformer.new
        mt.strip_db_names << ActiveRecord::Base.configurations[Rails.env]['database']
        mt.strip_schema_migration_versions = true

        msqls = Dir.glob(File.join(Rails.root, "db", "migrate_sql", '*.sql'))
        msqls.each do |sql_file|
          mig_name = File.basename(sql_file, ".sql")
          fout = Rails.root + "db/migrate/#{mig_name}.rb"
          mt.dump2migration(sql_file, fout.to_s)
          puts "Updated: #{File.basename(fout)}"
        end
      end
    end
  end
end

namespace :generate do
  desc "Generate a mytrilogy migration template file"
  task :migration, [:model_name, :down] => :environment do |task, options|
    require 'erb'
    @database = ActiveRecord::Base.configurations["production"]['database']
    migrate_directory = "#{Rails.root}/db/migrate"
    @time_stamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    file_name_prefix = "#{@time_stamp}_#{options[:model_name].underscore}"
    files = {
      "ruby_migration.erb" => "#{file_name_prefix}.rb",
      "sql_up_migration.erb" => "#{file_name_prefix}_up.sql"
    }
    files.merge!({"sql_down_migration.erb" => "#{file_name_prefix}_down.sql"}) unless options[:down] =~ /no-down/


    files.each do |file_name_in, file_name_out|
      erb_string = ERB.new(File.read("#{File.dirname(__FILE__)}/../mytrilogy/templates/#{file_name_in}")).result(binding)
      file_path = File.join(migrate_directory, file_name_out)

      File.open(file_path, 'w') do |file|
        file << erb_string
      end
    end
  end
end
