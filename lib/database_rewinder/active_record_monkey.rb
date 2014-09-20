module DatabaseRewinder
  module InsertRecorder
    def execute(sql, *)
      DatabaseRewinder.record_inserted_table self, sql
      super
    end

    def exec_query(sql, *)
      DatabaseRewinder.record_inserted_table self, sql
      super
    end
  end
end

begin
  require 'active_record/connection_adapters/sqlite3_adapter'
  ::ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :prepend, DatabaseRewinder::InsertRecorder
rescue LoadError
end
begin
  require 'active_record/connection_adapters/postgresql_adapter'
  ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, DatabaseRewinder::InsertRecorder
rescue LoadError
end
begin
  require 'active_record/connection_adapters/abstract_mysql_adapter'
  ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send :prepend, DatabaseRewinder::InsertRecorder
rescue LoadError
end
