require 'spec_helper'

describe DatabaseRewinder do
  before { DatabaseRewinder.init }

  describe '.[]' do
    before do
      DatabaseRewinder.instance_variable_set :'@db_config', {'foo' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}
      DatabaseRewinder[:aho, connection: 'foo']
    end
    subject { DatabaseRewinder.instance_variable_get(:'@cleaners').map {|c| c.connection_name} }
    it { should == ['foo'] }
  end

  describe '.record_inserted_table' do
    before do
      DatabaseRewinder.instance_variable_set :'@db_config', {'foo' => {'adapter' => 'sqlite3', 'database' => 'db/test.sqlite3'}}
      @cleaner = DatabaseRewinder.create_cleaner 'foo'
      connection = double('connection').as_null_object
      connection.instance_variable_set :'@config', {adapter: 'sqlite3', database: File.expand_path('db/test.sqlite3', Rails.root) }
      DatabaseRewinder.record_inserted_table(connection, 'INSERT INTO "foos" ("name") VALUES (?)')
    end
    subject { @cleaner }

    its(:inserted_tables) { should == ['foos'] }
  end

  describe '.clean' do
    before do
      Foo.create! name: 'foo1'
      Bar.create! name: 'bar1'
      DatabaseRewinder.clean
    end
    it 'should clean' do
      Foo.count.should == 0
      Bar.count.should == 0
    end
  end

  describe '.clean_all' do
    before do
      ActiveRecord::SchemaMigration.create_table
      ActiveRecord::SchemaMigration.create! version: '001'
      Foo.create! name: 'foo1'
      DatabaseRewinder.clean_all
    end
    after { ActiveRecord::SchemaMigration.drop_table }
    it 'should clean except schema_migrations' do
      Foo.count.should == 0
      ActiveRecord::SchemaMigration.count.should == 1
    end
  end
end
