# frozen_string_literal: true

module DatabaseRewinder
  class DummyModel < ActiveRecord::Base
    class << self
      def with_temporary_connection(config)
        establish_connection config
        yield connection
        connection.pool.disconnect!
      end
    end
  end
end
