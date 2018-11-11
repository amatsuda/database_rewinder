# frozen_string_literal: true

module DatabaseRewinder
  module MultipleStatementsExecutor
    refine ActiveRecord::ConnectionAdapters::AbstractAdapter do
      def supports_multiple_statements?
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        %w(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter ActiveRecord::ConnectionAdapters::Mysql2Adapter ActiveRecord::ConnectionAdapters::SQLite3Adapter).include? self.class.name
      end

      def execute_multiple(sql)
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        case self.class.name
        when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
          disable_referential_integrity { log(sql) { @connection.exec sql } }
        when 'ActiveRecord::ConnectionAdapters::Mysql2Adapter'
          if @connection.query_options[:connect_flags] & Mysql2::Client::MULTI_STATEMENTS != 0
            disable_referential_integrity do
              _result = log(sql) { @connection.query sql }
              while @connection.next_result
                # just to make sure that all queries are finished
                _result = @connection.store_result
              end
            end
          else
            query_options = @connection.query_options.dup
            query_options[:connect_flags] |= Mysql2::Client::MULTI_STATEMENTS
            # opens another connection to the DB
            client = Mysql2::Client.new query_options
            begin
              # disable_referential_integrity
              client.query("SET FOREIGN_KEY_CHECKS = 0")
              _result = log(sql) { client.query sql }
              while client.next_result
                # just to make sure that all queries are finished
                _result = client.store_result
              end
            ensure
              client.close
            end
          end
        when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
          disable_referential_integrity { log(sql) { @connection.execute_batch sql } }
        else
          raise 'Multiple deletion is not supported with the current database adapter.'
        end
      end
    end
  end
end
