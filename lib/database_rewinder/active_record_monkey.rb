# frozen_string_literal: true

module DatabaseRewinder
  module InsertRecorder
    # This method actually no longer has to be a `prepended` hook because InsertRecorder is a module without a direct method now, but still doing this just for compatibility
    def self.prepended(mod)
      [:execute, :exec_insert, :exec_query, :internal_exec_query].each do |method_name|
        if mod.instance_methods.include?(method_name) && (meth = mod.instance_method(method_name))
          method_body = if meth.parameters.any? {|type, _name| [:key, :keyreq, :keyrest].include? type }
            <<-RUBY
              def #{method_name}(sql, *, **)
                DatabaseRewinder.record_inserted_table self, sql
                super
              end
            RUBY
          else
            <<-RUBY
              def #{method_name}(sql, *)
                DatabaseRewinder.record_inserted_table self, sql
                super
              end
            RUBY
          end

          mod.send :prepend, Module.new { class_eval method_body }
        end
      end
    end
  end
end


# Already loaded adapters (SQLite3Adapter, PostgreSQLAdapter, AbstractMysqlAdapter, and possibly another third party adapter)
::ActiveRecord::ConnectionAdapters::AbstractAdapter.descendants.each do |adapter|
  # In order not to touch AbstractMysqlAdapter thing, but to surely patch the concrete classes
  next if adapter.descendants.any?

  adapter.send :prepend, DatabaseRewinder::InsertRecorder unless adapter < DatabaseRewinder::InsertRecorder
end

# Third party adapters that might be loaded in the future
def (::ActiveRecord::ConnectionAdapters::AbstractAdapter).inherited(adapter)
  adapter.send :prepend, DatabaseRewinder::InsertRecorder
end
