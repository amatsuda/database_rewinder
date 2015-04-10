require_relative 'database_rewinder/cleaner'

module DatabaseRewinder
  VERSION = Gem.loaded_specs['database_rewinder'].version.to_s

  class << self
    # Set your DB configuration here if you'd like to use something else than the AR configuration
    attr_writer :database_configuration

    def init
      @cleaners, @table_names_cache, @clean_all, @only, @except, @database_configuration = [], {}, false
    end

    def database_configuration
      @database_configuration || ActiveRecord::Base.configurations
    end

    def create_cleaner(connection_name)
      config = database_configuration[connection_name] or raise %Q[Database configuration named "#{connection_name}" is not configured.]

      Cleaner.new(config: config, connection_name: connection_name, only: @only, except: @except).tap {|c| @cleaners << c}
    end

    # In order to add another database to cleanup, you can give its connection name in on of the forms below:
    #
    #    # the simplest form
    #    DatabaseRewinder['the_db_name']
    #
    # or
    #
    #    # with connection: key
    #    DatabaseRewinder[connection: 'the_db_name']
    #
    # or
    #
    #    # DatabaseCleaner compatible
    #    DatabaseRewinder[:active_record, connection: 'the_db_name']
    #
    # You can cleanup multiple databases for each test using this configuration.
    def [](connection)
      @cleaners.detect {|c| c.connection_name == connection} || create_cleaner(connection)
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
      cleaner = cleaners.detect {|c| config[:database] =~ %r(#{c.db}$)} or return

      match = sql.match(/\AINSERT INTO (?:\.*[`"]?([^.\s`"]+)[`"]?)*/i)

      return unless match && table = match[1]
      cleaner.inserted_tables << table unless cleaner.inserted_tables.include? table
      cleaner.pool ||= connection.pool
    end

    def clean
      if @clean_all
        clean_all
      else
        cleaners.each(&:clean)
      end
    end

    def clean_all
      cleaners.each(&:clean_all)
    end

    # cache AR connection.tables
    def all_table_names(connection)
      db = connection.pool.spec.config[:database]
      @table_names_cache[db] ||= connection.tables.reject{|t| t == ActiveRecord::Migrator.schema_migrations_table_name }
    end
  end
end

begin
  require 'rails'
  require_relative 'database_rewinder/railtie'
rescue LoadError
  DatabaseRewinder.init
  require_relative 'database_rewinder/active_record_monkey'
end
