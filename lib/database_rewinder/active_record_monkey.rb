# frozen_string_literal: true
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

def (::ActiveRecord::ConnectionAdapters::AbstractAdapter).inherited(adapter)
  adapter.prepend DatabaseRewinder::InsertRecorder
end
