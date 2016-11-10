# frozen_string_literal: true
module DatabaseRewinder
  module MultipleStatementsExecutor
    refine ActiveRecord::ConnectionAdapters::AbstractAdapter do
      def supports_multiple_statements?
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        %w(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter ActiveRecord::ConnectionAdapters::Mysql2Adapter ActiveRecord::ConnectionAdapters::SQLite3Adapter).include? self.class.name
      end

      def execute_multiple(sql, name = nil)
        #TODO Use ADAPTER_NAME when we've dropped AR 4.1 support
        case self.class.name
        when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
          log(sql) { @connection.exec sql }
        when 'ActiveRecord::ConnectionAdapters::Mysql2Adapter'
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
        when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
          log(sql) { @connection.execute_batch sql }
        else
          execute sql, name
        end
      end
    end
  end
end
