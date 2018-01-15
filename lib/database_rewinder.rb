# frozen_string_literal: true
require_relative 'database_rewinder/cleaner'

module DatabaseRewinder
  VERSION = Gem.loaded_specs['database_rewinder'].version.to_s

  INSERT_REGEXP = /\A
        \s*(?:
          (?:LOAD\s+DATA(?:\s+(?:LOW_PRIORITY|CONCURRENT))?(?:\s+LOCAL)?\s+INFILE\s+\S+(?:\s+(REPLACE|IGNORE))?\s+INTO\s+TABLE)
          |
          (?:INSERT(?:\s+IGNORE)?(?:\s+INTO)?)
        )
        \s+
        (?:\.*[`"]?(?<table_name>[^.\s`"]+)[`"]?)*
      /ix

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
      database = config[:database]
      #NOTE What's the best way to get the app dir besides Rails.root? I know Dir.pwd here might not be the right solution, but it should work in most cases...
      root_dir = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : Dir.pwd
      cleaner = cleaners.detect do |c|
        if (config[:adapter] == 'sqlite3') && (config[:database] != ':memory:')
          File.expand_path(c.db, root_dir) == File.expand_path(database, root_dir)
        else
          c.db == database
        end
      end or return

      match = sql.match(INSERT_REGEXP)
      return unless match

      table = match['table_name']
      if table
        cleaner.inserted_tables << table unless cleaner.inserted_tables.include? table
        cleaner.pool ||= connection.pool
      end
    end

    def clean(multiple: true)
      if @clean_all
        clean_all multiple: multiple
      else
        cleaners.each {|c| c.clean multiple: multiple}
      end
    end

    def clean_all(multiple: true)
      cleaners.each {|c| c.clean_all multiple: multiple}
    end

    # cache AR connection.tables
    def all_table_names(connection)
      cache_key = connection.pool.spec.config
      #NOTE connection.tables warns on AR 5 with some adapters
      tables = ActiveSupport::Deprecation.silence { connection.tables }
      @table_names_cache[cache_key] ||= tables.reject do |t|
        (t == ActiveRecord::SchemaMigration.table_name) ||
        (ActiveRecord::Base.respond_to?(:internal_metadata_table_name) && (t == ActiveRecord::Base.internal_metadata_table_name))
      end
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
