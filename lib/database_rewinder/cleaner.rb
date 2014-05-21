module DatabaseRewinder
  class Cleaner
    attr_accessor :db, :connection_name, :inserted_tables, :pool

    def initialize(db: nil, connection_name: nil, only: nil, except: nil)
      @db, @connection_name, @only, @except = db, connection_name, Array(only), Array(except)
      reset
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
      ar_conn = pool ? pool.connection : ActiveRecord::Base.connection

      delete_all ar_conn, DatabaseRewinder.all_table_names(ar_conn)
      reset
    end

    def clean_with(_strategy, only: nil, except: nil, **)
      originals = @only, @except
      @only, @except = Array(only), Array(except)
      clean_all
      @only, @except = originals
    end

    # for database_cleaner compat
    def strategy=(args)
      options = args.is_a?(Array) ? args.extract_options! : {}
      @only += Array(options[:only]) unless options[:only].blank?
      @except += Array(options[:except]) unless options[:except].blank?
    end

    private
    def delete_all(ar_conn, tables)
      tables = tables & @only if @only.any?
      tables -= @except if @except.any?
      return if tables.empty?

      ar_conn.disable_referential_integrity do
        tables.each do |table_name|
          ar_conn.execute "DELETE FROM #{ar_conn.quote_table_name(table_name)};"
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
