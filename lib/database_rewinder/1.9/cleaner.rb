# -*- coding: utf-8 -*-
module DatabaseRewinder
  class Cleaner
    attr_accessor :db, :connection_name, :inserted_tables, :pool

    def initialize(*args)
      options = args.extract_options!
      @db, @connection_name, @only, @except = options[:db], options[:connection_name], Array(options[:only]), Array(options[:except])
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

    def clean_with(*args)
      options = args.extract_options!
      only = options[:only]
      @only += Array(only) unless only.blank?
      except = options[:except]
      @except += Array(except) unless except.blank?
      clean_all
    end

    # for database_cleaner compat
    def strategy=(*args)
      options = args.extract_options!
      only = options[:only]
      @only += Array(only) unless only.blank?
      except = options[:except]
      @except += Array(except) unless except.blank?
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
