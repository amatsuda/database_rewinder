# frozen_string_literal: true

module DatabaseRewinder
  module InsertRecorder
    def execute(sql, *)
      DatabaseRewinder.record_inserted_table self, sql
      super
    end

    if ActiveRecord::VERSION::MAJOR < 5
      def exec_query(sql, *)
        DatabaseRewinder.record_inserted_table self, sql
        super
      end
    else
      def exec_query(sql, *, **)
        DatabaseRewinder.record_inserted_table self, sql
        super
      end
    end
  end
end

::ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :prepend, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::SQLite3Adapter
::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send :prepend, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter

def (::ActiveRecord::ConnectionAdapters::AbstractAdapter).inherited(adapter)
  adapter.prepend DatabaseRewinder::InsertRecorder
end
