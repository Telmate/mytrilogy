require 'treetop'
$mystmt_delimiter = nil

module Mytrilogy

  # Defines MysqlStatmentsParser
  Treetop.load "#{File.dirname(__FILE__)}/mysql_statements"

  class MysqlTransformer

    attr_accessor :strip_definer, :strip_db_names

    def initialize
      $mystmt_delimiter = nil
      @strip_definer = true
      @strip_db_names = []
      @parser = MysqlStatmentsParser.new
    end

    def parse(script)
      $mystmt_delimiter = nil
      @parser.parse(script)
    end

    def sql2ruby(script, ruby_cmd = "execute")
      st = parse(script)
      raise "Problem with SQL parsing: #{@parser.failure_reason}" if st.nil?
      lines = []
      st.statements.each { |stmt|
        sstmt = stmt.strip.gsub("\\","\\\\\\\\")
        unless sstmt.blank?

          # TODO - move stripping powers into the treetop
          # Strip DEFINER=`root`@`localhost` parts
          sstmt.gsub!(/DEFINER=[^\s\*]+/, "") if @strip_definer

          # Strip `name`.xxxx
          # TODO - need to track 'USE databasename' statements to know when to not strip
          # if ! @strip_db_names.empty?
          #   dbname_rx = Regexp.new @strip_db_names.collect {|dbn| ["#{dbn}\\.", "`#{dbn}`\\."] }.flatten.join('|')
          #   sstmt.gsub!(dbname_rx, "")
          # end

          if sstmt =~ /\n|"/
            lines << "#{ruby_cmd} <<_SQL_\n#{sstmt}\n_SQL_\n"
          else
            lines << "#{ruby_cmd} \"#{sstmt}\""
          end
        end
      }
      lines.join("\n")
    end


    def dump2migration(fname_in, fname_out)
      body = sql2ruby(open(fname_in).read, "    execute")
      basename = File.basename(fname_out)
      if basename =~ /^[0-9]+_(.*).rb$/
          clsname = $1.camelize
          open(fname_out, "w+") { |out|
              out.write "
class #{clsname} < ActiveRecord::Migration

  def up
    ######## BEGIN Mytrilogy::MysqlTransformer.dump2migration
#{body}
    execute \"USE \#{ActiveRecord::Base.configurations[Rails.env]['database']}\"
    ######## END Mytrilogy::MysqlTransformer.dump2migration
  end

  def down
    # TODO
  end

end
"
          }
      else
        open(fname_out, "w+") { |out| out.write body }
      end

    end

  end

end

=begin
require 'mytrilogy/mysql_transformer'
mt = Mytrilogy::MysqlTransformer.new
puts mt.sql2ruby("SELECT * FROM foo;SELECT * FROM bax")
=end