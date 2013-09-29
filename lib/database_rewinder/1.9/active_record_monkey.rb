# -*- coding: utf-8 -*-
module DatabaseRewinder
  module InsertRecorder
    extend ActiveSupport::Concern

    included do
      alias_method_chain :execute, :insert_recorder
      alias_method_chain :exec_query, :insert_recorder
    end

    def execute_with_insert_recorder(sql, name=nil)
      DatabaseRewinder.record_inserted_table self, sql
      execute_without_insert_recorder(sql, name)
    end

    def exec_query_with_insert_recorder(sql, name='SQL', binds=[])
      DatabaseRewinder.record_inserted_table self, sql
      exec_query_without_insert_recorder(sql, name, binds)
    end
  end
end

::ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::SQLite3Adapter
::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send :include, DatabaseRewinder::InsertRecorder if defined? ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
