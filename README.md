# Mytrilogy

Mysql utils for migrations and stored procedures.

##  Features

Replaces the **db:test:prepare** with a mysqldump sequence which attempts to safely duplicate triggers and store procedures.

Provides a includable module **ActiverecordStoredprocedure** which provides a **find_by_procedure** ActiveRecord method for calling stored procedures from models as well as handling and mapping MySQL signals to ruby exceptions.

Provides rake tasks for converting multi-statement SQL files into rails database migrations.


## Installation

Add this line to your application's Gemfile:

    gem 'mytrilogy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mytrilogy

## Usage


### ActiveRecord:

    class MyRecord < ActiveRecord::Base
		include ActiverecordStoredprocedure
    end
    
    # The columns returned from 'name_of_procedure' become the columns of the
    # MyRecord instance.

    MyRecord.find_by_procedure(:name_of_procedure, 'param1', 'param2')
    
    # Uses ActiveRecord '?' to replace parameter values with SQL type safe values
    
    # To execute without result set
    MyRecord.call_procedure(:name_of_procedure, 'param1', 'param2')
    
    
MySQL procedures can signal errors in a format that triggers familiar ruby exceptions. Example:

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '#ActiveRecord::RecordNotFound# Unable to find or create MyRecord';

The ActiverecordStoredprocedure will convert and raise classes named between to hash '#' symbols.

### Rake tasks:

Prepare a test database with triggers and more:

    $ rake db:test:prepare

Convert multi-statement sql file to a migration file:

	$ rake db:mysql:sql2rb IN=/tmp/somefile.sql OUT=db/migrate/20130319210111_some_sql.rb

Convert a dump of the current database environment to a migration file:
 
    $ rake db:mysql:dump2rb OUT=db/migrate/20130214210111_copy_schema.rb
    
Convert potentially updated db:migrate_sql output back to a ruby migration
	
	$ rake rake db:mysql:migrate_sql2rb


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
