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

    def clean
      return if !pool || inserted_tables.empty?

      # When the application uses multiple database connections, a connection
      # pool used in test could be already removed (i.e., pool.connected? = false).
      # In this case, we have to reconnect to the database to clean inserted
      # tables.
      with_automatic_reconnect(pool) do
        delete_all (ar_conn = pool.connection), DatabaseRewinder.all_table_names(ar_conn) & inserted_tables
      end
      reset
    end

    def clean_all
      if pool
        ar_conn = pool.connection
        delete_all ar_conn, DatabaseRewinder.all_table_names(ar_conn)
      else
        require 'database_rewinder/dummy_model'
        DummyModel.with_temporary_connection(config) do |ar_conn|
          delete_all ar_conn, DatabaseRewinder.all_table_names(ar_conn)
        end
      end

      reset
    end

    private
    def delete_all(ar_conn, tables)
      tables = tables & @only if @only.any?
      tables -= @except if @except.any?
      return if tables.empty?

      ar_conn.disable_referential_integrity do
        case ar_conn.pool.spec.config[:adapter]
        when 'mysql2'
          begin
            query_options = ar_conn.instance_variable_get(:@connection).query_options
            query_options[:connect_flags] |= Mysql2::Client::MULTI_STATEMENTS
            client = Mysql2::Client.new query_options
            sql = tables.inject('') {|s, table_name| s += "DELETE FROM #{ar_conn.quote_table_name(table_name)};"}
            begin
              ar_conn.send(:log, sql) { client.query sql }
            ensure
              client.close
            end
          rescue
            tables.each do |table_name|
              ar_conn.execute "DELETE FROM #{ar_conn.quote_table_name(table_name)};"
            end
          end
        else
          tables.each do |table_name|
            ar_conn.execute "DELETE FROM #{ar_conn.quote_table_name(table_name)};"
          end
        end
      end
    end

    def reset
      @inserted_tables = []
    end

    def with_automatic_reconnect(pool, &block)
      reconnect = pool.automatic_reconnect
      pool.automatic_reconnect = true
      block.call
    ensure
      pool.automatic_reconnect = reconnect
    end
  end
end

require_relative 'compatibility'
