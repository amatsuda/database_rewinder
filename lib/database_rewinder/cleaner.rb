# frozen_string_literal: true

require_relative 'multiple_statements_executor'

using DatabaseRewinder::MultipleStatementsExecutor

module DatabaseRewinder
  class Cleaner
    attr_accessor :config, :connection_name, :only, :except, :inserted_tables, :pool

    def initialize(config: nil, connection_name: nil, only: nil, except: nil)
      @config, @connection_name, @only, @except = config, connection_name, Array(only), Array(except)
      reset
    end

    def db
      config['database']
    end

    def clean(multiple: true)
      return if !pool || inserted_tables.empty?

      # When the application uses multiple database connections, a connection
      # pool used in test could be already removed (i.e., pool.connected? = false).
      # In this case, we have to reconnect to the database to clean inserted
      # tables.
      with_automatic_reconnect(pool) do
        delete_all (ar_conn = pool.connection), DatabaseRewinder.all_table_names(ar_conn) & inserted_tables, multiple: multiple
      end
      reset
    end

    def clean_all(multiple: true)
      if pool
        ar_conn = pool.connection
        delete_all ar_conn, DatabaseRewinder.all_table_names(ar_conn), multiple: multiple
      else
        require 'database_rewinder/dummy_model'
        DummyModel.with_temporary_connection(config) do |temporary_connection|
          delete_all temporary_connection, DatabaseRewinder.all_table_names(temporary_connection), multiple: multiple
        end
      end

      reset
    end

    private
    def delete_all(ar_conn, tables, multiple: true)
      tables = tables & @only if @only.any?
      tables -= @except if @except.any?
      # in order to avoid referential integrity error as much as possible
      tables.reverse!
      return if tables.empty?

      if multiple && tables.many? && ar_conn.supports_multiple_statements?
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        if (ar_conn.class.name == 'ActiveRecord::ConnectionAdapters::Mysql2Adapter') && ar_conn.transaction_open?
          # Print the warning message, then fall back to non-multiple deletion
          Kernel.warn "WARNING: You may be executing DatabaseRewinder inside a transactional test. You're presumably misconfiguring your tests. Please read DatabaseRewinder's document, and properly configure your tests."
        else
          ar_conn.execute_multiple tables.map {|t| "DELETE FROM #{ar_conn.quote_table_name(t)}"}.join(';')
          return
        end
      end

      ar_conn.disable_referential_integrity do
        tables.each do |table_name|
          ar_conn.execute "DELETE FROM #{ar_conn.quote_table_name(table_name)};"
        end
      end
    end

    def reset
      @inserted_tables = []
    end

    def with_automatic_reconnect(pool)
      reconnect = pool.automatic_reconnect
      pool.automatic_reconnect = true
      yield
    ensure
      pool.automatic_reconnect = reconnect
    end
  end
end

require_relative 'compatibility'
