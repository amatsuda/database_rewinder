# frozen_string_literal: true

require 'test_helper'

class DatabaseRewinder::CleanerTest < ActiveSupport::TestCase
  sub_test_case '#strategy=' do
    setup { @cleaner = DatabaseRewinder::Cleaner.new(only: ['foos'], except: 'bars') }

    test 'without options' do
      @cleaner.strategy = :truncation

      # it should keep instance variables
      assert_equal ['foos'], @cleaner.instance_variable_get(:@only)
      assert_equal ['bars'], @cleaner.instance_variable_get(:@except)
    end

    test 'with options (an array or a string)' do
      @cleaner.strategy = :truncation, { only: ['bars'], except: 'bazs' }

      # it should overwrite instance variables
      assert_equal ['bars'], @cleaner.instance_variable_get(:@only)
      assert_equal ['bazs'], @cleaner.instance_variable_get(:@except)
    end

    test 'with options (an empty array or nil)' do
      @cleaner.strategy = :truncation, { only: [], except: nil }

      # it should overwrite instance variables even if they are empty/nil
      assert_equal [], @cleaner.instance_variable_get(:@only)
      assert_equal [], @cleaner.instance_variable_get(:@except)
    end
  end
end
