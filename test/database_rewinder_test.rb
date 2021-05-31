# frozen_string_literal: true

require 'test_helper'

class DatabaseRewinder::DatabaseRewinderTest < ActiveSupport::TestCase
  if ActiveRecord::VERSION::MAJOR >= 5
    self.use_transactional_tests = false
  else
    self.use_transactional_fixtures = false
  end

  setup do
    DatabaseRewinder.init
  end

  sub_test_case '.[]' do
    teardown do
      DatabaseRewinder.database_configuration = nil
    end
    sub_test_case 'for connecting to an arbitrary database' do
      def assert_cleaners_added(cleaner_names)
        connection_names =  DatabaseRewinder.instance_variable_get(:'@cleaners').map {|c| c.connection_name}
        yield
        assert_equal cleaner_names, DatabaseRewinder.instance_variable_get(:'@cleaners').map {|c| c.connection_name} - connection_names
      end

      test 'simply giving a connection name only' do
        assert_cleaners_added ['aaa'] do
          DatabaseRewinder.database_configuration = {'aaa' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}
          DatabaseRewinder['aaa']
        end
      end

      test 'giving a connection name via Hash with :connection key' do
        assert_cleaners_added ['bbb'] do
          DatabaseRewinder.database_configuration = {'bbb' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}
          DatabaseRewinder[connection: 'bbb']
        end
      end

      test 'the Cleaner compatible syntax' do
        assert_cleaners_added ['ccc'] do
          DatabaseRewinder.database_configuration = {'ccc' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}
          DatabaseRewinder[:aho, connection: 'ccc']
        end
      end

      if ActiveRecord::VERSION::MAJOR >= 6
        sub_test_case 'with traditional configurations' do
          test 'simply giving a connection name only' do
            assert_cleaners_added ['aaa'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'aaa' => {'adapter' => 'sqlite3', 'database' => ':memory:'}})
              DatabaseRewinder['aaa']
            end
          end

          test 'giving a connection name via Hash with :connection key' do
            assert_cleaners_added ['bbb'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'bbb' => {'adapter' => 'sqlite3', 'database' => ':memory:'}})
              DatabaseRewinder[connection: 'bbb']
            end
          end

          test 'the Cleaner compatible syntax' do
            assert_cleaners_added ['ccc'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'ccc' => {'adapter' => 'sqlite3', 'database' => ':memory:'}})
              DatabaseRewinder[:aho, connection: 'ccc']
            end
          end
        end

        sub_test_case 'with multiple database configurations' do
          test 'simply giving a connection name only' do
            assert_cleaners_added ['aaa'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'test' => {'aaa' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}})
              DatabaseRewinder['aaa']
            end
          end

          test 'giving a connection name via Hash with :connection key' do
            assert_cleaners_added ['bbb'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'test' => {'bbb' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}})
              DatabaseRewinder[connection: 'bbb']
            end
          end

          test 'the Cleaner compatible syntax' do
            assert_cleaners_added ['ccc'] do
              DatabaseRewinder.database_configuration = ActiveRecord::DatabaseConfigurations.new({'test' => {'ccc' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}})
              DatabaseRewinder[:aho, connection: 'ccc']
            end
          end
        end
      end
    end

    test 'for connecting to multiple databases' do
      DatabaseRewinder[:active_record, connection: 'test']
      DatabaseRewinder[:active_record, connection: 'test2']

      Foo.create! name: 'foo1'
      Quu.create! name: 'quu1'

      DatabaseRewinder.clean

      # it should clean all configured databases
      assert_equal 0, Foo.count
      assert_equal 0, Quu.count
    end
  end

  sub_test_case '.record_inserted_table' do
    setup do
      DatabaseRewinder.cleaners
    end

    def perform_insert(sql)
      @cleaner = DatabaseRewinder.instance_variable_get(:'@cleaners').detect {|c| c.db == (ENV['DB'] == 'sqlite3' ? 'db/database_rewinder_test.sqlite3' : 'database_rewinder_test')}

      connection = ::ActiveRecord::Base.connection
      DatabaseRewinder.record_inserted_table(connection, sql)
    end
    teardown do
      DatabaseRewinder.database_configuration = nil
    end

    sub_test_case 'via General Active Record insertions' do
      setup do
        DatabaseRewinder.cleaners
        @cleaner = DatabaseRewinder.instance_variable_get(:'@cleaners').detect {|c| c.db == (ENV['DB'] == 'sqlite3' ? 'db/database_rewinder_test.sqlite3' : 'database_rewinder_test')}
      end

      test 'create' do
        Bar.create name: 'bar1'
        assert_equal ['bars'], @cleaner.inserted_tables
      end

      if ActiveRecord::VERSION::MAJOR >= 6
        test 'insert_all' do
          Bar.insert_all! [{name: 'bar1'}]
          assert_equal ['bars'], @cleaner.inserted_tables
        end
      end
    end

    sub_test_case 'common database' do
      test 'include database name' do
        perform_insert 'INSERT INTO "database"."foos" ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end
      test 'only table name' do
        perform_insert 'INSERT INTO "foos" ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end
      test 'without "INTO"' do
        perform_insert 'INSERT "foos" ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end
      test 'with space before "INSERT"' do
        perform_insert <<-SQL
          INSERT INTO "foos" ("name") VALUES (?)
        SQL
        assert_equal ['foos'], @cleaner.inserted_tables
      end
      test 'without spaces between table name and columns list' do
        perform_insert 'INSERT INTO foos(name) VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end

      test 'with multi statement query' do
        perform_insert <<-SQL
          INSERT INTO "foos" ("name") VALUES (?);
          INSERT INTO "bars" ("name") VALUES (?)
        SQL
        assert_equal ['foos', 'bars'], @cleaner.inserted_tables
      end
    end

    sub_test_case 'Database accepts more than one dots in an object notation (e.g. SQLServer)' do
      test 'full joined' do
        perform_insert 'INSERT INTO server.database.schema.foos ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end
      test 'missing one' do
        perform_insert 'INSERT INTO database..foos ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end

      test 'missing two' do
        perform_insert 'INSERT INTO server...foos ("name") VALUES (?)'
        assert_equal ['foos'], @cleaner.inserted_tables
      end
    end

    test 'when database accepts INSERT IGNORE INTO statement' do
      perform_insert "INSERT IGNORE INTO `foos` (`name`) VALUES ('alice'), ('bob') ON DUPLICATE KEY UPDATE `foos`.`updated_at`=VALUES(`updated_at`)"
      assert_equal ['foos'], @cleaner.inserted_tables
    end
  end

  test '.clean' do
    bar = Bar.create! name: 'bar1'
    Foo.create! name: 'foo1', bar_id: bar.id
    DatabaseRewinder.clean

    assert_equal 0, Foo.count
    assert_equal 0, Bar.count
  end

  if ActiveRecord::VERSION::MAJOR >= 4
    sub_test_case 'migrations' do
      test '.clean_all should not touch AR::SchemaMigration' do
        begin
          ActiveRecord::SchemaMigration.create_table
          ActiveRecord::SchemaMigration.create! version: '001'
          DatabaseRewinder.clean_all

          assert_equal 0, Foo.count
          assert_equal 1, ActiveRecord::SchemaMigration.count
        ensure
          ActiveRecord::SchemaMigration.drop_table
        end
      end
    end
  end

  sub_test_case '.clean_with' do
    def perform_clean(options)
      @cleaner = DatabaseRewinder.cleaners.first
      @only = @cleaner.instance_variable_get(:@only)
      @except = @cleaner.instance_variable_get(:@except)
      Foo.create! name: 'foo1'
      Bar.create! name: 'bar1'
      DatabaseRewinder.clean_with :truncation, **options
    end

    test 'with only option' do
      perform_clean only: ['foos']
      assert_equal 0, Foo.count
      assert_equal 1, Bar.count
      assert_equal @only, @cleaner.instance_variable_get(:@only)
    end

    test 'with except option' do
      perform_clean except: ['bars']
      assert_equal 0, Foo.count
      assert_equal 1, Bar.count
      assert_equal @except, @cleaner.instance_variable_get(:@except)
    end
  end

  sub_test_case '.cleaning' do
    test 'without exception' do
      DatabaseRewinder.cleaning do
        Foo.create! name: 'foo1'
      end

      assert_equal 0, Foo.count
    end

    test 'with exception' do
      assert_raises do
        DatabaseRewinder.cleaning do
          Foo.create! name: 'foo1'; fail
        end
      end
      assert_equal 0, Foo.count
    end
  end

  sub_test_case '.strategy=' do
    sub_test_case 'call first with options' do
      setup do
        DatabaseRewinder.strategy = :truncate, { only: ['foos'], except: ['bars'] }
      end

      test 'should set options' do
        assert_equal ['foos'], DatabaseRewinder.instance_variable_get(:@only)
        assert_equal ['bars'], DatabaseRewinder.instance_variable_get(:@except)
      end

      test 'should create cleaner with options' do
        cleaner = DatabaseRewinder.instance_variable_get(:@cleaners).first
        assert_equal ['foos'], cleaner.instance_variable_get(:@only)
        assert_equal ['bars'], cleaner.instance_variable_get(:@except)
      end

      sub_test_case 'call again with different options' do
        setup do
          DatabaseRewinder.strategy = :truncate, { only: ['bazs'], except: [] }
        end

        test 'should overwrite options' do
          assert_equal ['bazs'], DatabaseRewinder.instance_variable_get(:@only)
          assert_equal [], DatabaseRewinder.instance_variable_get(:@except)
        end

        test 'should overwrite cleaner with new options' do
          cleaner = DatabaseRewinder.instance_variable_get(:@cleaners).first
          assert_equal ['bazs'], cleaner.instance_variable_get(:@only)
          assert_equal [], cleaner.instance_variable_get(:@except)
        end
      end
    end
  end
end
