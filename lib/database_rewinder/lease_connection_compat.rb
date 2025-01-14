# frozen_string_literal: true

module DatabaseRewinder
  module LeaseConnectionCompat
    # Make old AR compatible with AR >= 7.2 by defining `lease_connection`
    unless ActiveRecord::ConnectionAdapters::ConnectionPool.instance_methods.include? :lease_connection
      refine ActiveRecord::ConnectionAdapters::ConnectionPool do
        def lease_connection
          connection
        end
      end
    end
  end
end
