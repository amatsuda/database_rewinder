# frozen_string_literal: true

require 'test_helper'

class DatabaseRewinder::InsertRecorderTest < ActiveSupport::TestCase
  setup do
    DatabaseRewinder.init
    Foo.create! name: 'foo1'
    Bar.connection.execute "insert into bars (name) values ('bar1')"
    DatabaseRewinder.cleaners
  end

  test '#execute' do
    cleaner = DatabaseRewinder.instance_variable_get(:'@cleaners').detect {|c| c.db == (ENV['DB'] == 'sqlite3' ? 'db/database_rewinder_test.sqlite3' : 'database_rewinder_test')}

    assert_equal %w(foos bars), cleaner.inserted_tables
    assert_not_nil cleaner.pool
  end
end
