# frozen_string_literal: true
module DatabaseRewinder
  module MultipleStatementsExecutor
    refine ActiveRecord::ConnectionAdapters::AbstractAdapter do
      def supports_multiple_statements?
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        %w(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter ActiveRecord::ConnectionAdapters::Mysql2Adapter ActiveRecord::ConnectionAdapters::SQLite3Adapter).include? self.class.name
      end

      def delete_multiple(tables)
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        case self.class.name
        when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
          sql = tables_to_one_delete_sql tables
          disable_referential_integrity { log(sql) { @connection.exec sql } }

        when 'ActiveRecord::ConnectionAdapters::Mysql2Adapter'
          if @connection.query_options[:connect_flags] & Mysql2::Client::MULTI_STATEMENTS != 0
            disable_referential_integrity do
              sql = tables_to_one_delete_sql tables
              _result = log(sql) { @connection.query sql }
              while @connection.next_result
                # just to make sure that all queries are finished
                _result = @connection.store_result
              end
            end

          else
            @connection.query 'drop procedure if exists rewind_em_all'
            @connection.query <<-SQL
create procedure rewind_em_all(in tables text, in num integer) begin declare i int default 0; while i < num do set i = i + 1; set @delete_sql = concat('DELETE FROM ', substring_index(substring_index(tables, ',', i), ',', -1)); prepare stmt from @delete_sql; execute stmt; deallocate prepare stmt; end while; end;
SQL
            disable_referential_integrity do
              @connection.query "call rewind_em_all('#{tables.join(',')}', #{tables.length})"
            end
          end

        when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
          sql = tables_to_one_delete_sql tables
          disable_referential_integrity { log(sql) { @connection.execute_batch sql } }

        else
          raise 'Multiple deletion is not supported with the current database adapter.'
        end
      end

      private
      def tables_to_one_delete_sql(tables)
        tables.map {|t| "DELETE FROM #{quote_table_name(t)}"}.join(';')
      end
    end
  end
end
