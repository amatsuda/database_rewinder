if RUBY_VERSION >= '2.0.0'
  require_relative 'database_rewinder/cleaner'
  require_relative 'database_rewinder/cleaner_creation'
  require_relative 'database_rewinder/database_cleaner_compat'
else
  require_relative 'database_rewinder/1.9.3/cleaner'
  require_relative 'database_rewinder/1.9.3/cleaner_creation'
  require_relative 'database_rewinder/1.9.3/database_cleaner_compat'
end
require_relative 'database_rewinder/railtie'

module DatabaseRewinder
  VERSION = Gem.loaded_specs['database_rewinder'].version.to_s

  class << self
    include DatabaseRewinder::CleanerCreation
    include DatabaseRewinder::DatabaseCleanerCompat

    def init
      @cleaners, @table_names_cache, @clean_all, @only, @except = [], {}, false
      @db_config = YAML::load(ERB.new(Rails.root.join('config/database.yml').read).result)
    end

    def all=(v)
      @clean_all = v
    end

    def cleaners
      create_cleaner 'test' if @cleaners.empty?
      @cleaners
    end

    def record_inserted_table(connection, sql)
      config = connection.instance_variable_get(:'@config')
      database = config[:database]
      cleaner = cleaners.detect do |c|
        if (config[:adapter] == 'sqlite3') && (config[:database] != ':memory:')
          File.expand_path(c.db, Rails.root) == File.expand_path(database, Rails.root)
        else
          c.db == database
        end
      end or return

      match = sql.match(/\AINSERT INTO [`"]?([^\s`"]+)[`"]?/i)
      table = match[1] if match
      if table
        cleaner.inserted_tables << table unless cleaner.inserted_tables.include? table
        cleaner.pool ||= connection.pool
      end
    end

    def clean
      if @clean_all
        clean_all
      else
        cleaners.each {|c| c.clean}
      end
    end

    def clean_all
      cleaners.each {|c| c.clean_all}
    end

    def clean_with(*args)
      cleaners.each {|c| c.clean_with *args}
    end

    # cache AR connection.tables
    def all_table_names(connection)
      db = connection.instance_variable_get(:'@config')[:database]
      @table_names_cache[db] ||= connection.tables
    end
  end
end
