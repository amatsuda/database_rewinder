module DatabaseRewinder
  class Cleaner
    attr_accessor :db, :connection_name, :inserted_tables, :pool

    def initialize(db: nil, connection_name: nil, only: nil, except: nil)
      @db, @connection_name, @only, @except = db, connection_name, Array(only), Array(except)
      reset
    end

    def clean
      return unless pool
      return if inserted_tables.empty?

      delete_all (ar_conn = pool.connection), DatabaseRewinder.all_table_names(ar_conn) & inserted_tables
      reset
    end

    def clean_all
      return unless pool

      delete_all (ar_conn = pool.connection), DatabaseRewinder.all_table_names(ar_conn)
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
  end
end
