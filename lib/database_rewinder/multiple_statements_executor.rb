# frozen_string_literal: true
module DatabaseRewinder
  module MultipleStatementsExecutor
    refine ActiveRecord::ConnectionAdapters::AbstractAdapter do
      def supports_multiple_statements?
        true
      end

      def execute_multiple(sql, name = nil)
        case self.class::ADAPTER_NAME
        when 'PostgreSQL'
          log(sql) { @connection.exec sql }
        when 'Mysql2'
          query_options = @connection.query_options.dup
          if query_options[:connect_flags] & Mysql2::Client::MULTI_STATEMENTS != 0
            log(sql) { @connection.query sql }
          else
            query_options[:connect_flags] |= Mysql2::Client::MULTI_STATEMENTS
            # opens another connection to the DB
            client = Mysql2::Client.new query_options
            begin
              log(sql) { client.query sql }
            ensure
              client.close
            end
          end
        when 'SQLite'
          log(sql) { @connection.execute_batch sql }
        else
          execute sql, name
        end
      end
    end
  end
end
