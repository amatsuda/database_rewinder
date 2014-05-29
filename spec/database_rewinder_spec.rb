require 'spec_helper'

describe DatabaseRewinder do
  before do
    DatabaseRewinder.init
  end

  describe '.[]' do
    before do
      DatabaseRewinder.database_configuration = {'foo' => {'adapter' => 'sqlite3', 'database' => ':memory:'}}
      DatabaseRewinder[:aho, connection: 'foo']
    end
    after do
      DatabaseRewinder.database_configuration = nil
    end
    subject { DatabaseRewinder.instance_variable_get(:'@cleaners').map {|c| c.connection_name} }
    it { should == ['foo'] }
  end

  describe '.record_inserted_table' do
    before do
      DatabaseRewinder.database_configuration = {'foo' => {'adapter' => 'sqlite3', 'database' => 'db/test.sqlite3'}}
      @cleaner = DatabaseRewinder.create_cleaner 'foo'
      connection = double('connection').as_null_object
      connection.instance_variable_set :'@config', {adapter: 'sqlite3', database: File.expand_path('db/test.sqlite3', Rails.root) }
      DatabaseRewinder.record_inserted_table(connection, 'INSERT INTO "foos" ("name") VALUES (?)')
    end
    after do
      DatabaseRewinder.database_configuration = nil
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

  describe '.clean_with' do
    before do
      @cleaner = DatabaseRewinder.cleaners.first
      @only = @cleaner.instance_variable_get(:@only)
      @except = @cleaner.instance_variable_get(:@except)
      Foo.create! name: 'foo1'
      Bar.create! name: 'bar1'
    end

    context 'simple arguments' do
      before do
        DatabaseRewinder.clean_with options
      end

      context 'with only option' do
        let(:options) { { only: ['foos'] } }
        it 'should clean with only option and restore original one' do
          Foo.count.should == 0
          Bar.count.should == 1
          expect(@cleaner.instance_variable_get(:@only)).to eq(@only)
        end
      end

      context 'with except option' do
        let(:options) { { except: ['bars'] } }
        it 'should clean with except option and restore original one' do
          Foo.count.should == 0
          Bar.count.should == 1
          expect(@cleaner.instance_variable_get(:@except)).to eq(@except)
        end
      end
    end


    context 'compatible arguments' do
      before do
        DatabaseRewinder.clean_with :truncation, options
      end

      context 'with only option' do
        let(:options) { { only: ['foos'] } }
        it 'should clean with only option and restore original one' do
          Foo.count.should == 0
          Bar.count.should == 1
          expect(@cleaner.instance_variable_get(:@only)).to eq(@only)
        end
      end

      context 'with except option' do
        let(:options) { { except: ['bars'] } }
        it 'should clean with except option and restore original one' do
          Foo.count.should == 0
          Bar.count.should == 1
          expect(@cleaner.instance_variable_get(:@except)).to eq(@except)
        end
      end
    end
  end

  describe '.strategy=' do
    context 'call first with options' do
      before do
        DatabaseRewinder.strategy = :truncate, { only: ['foos'], except: ['bars'] }
      end

      it 'should set options' do
        expect(DatabaseRewinder.instance_variable_get(:@only)).to eq(['foos'])
        expect(DatabaseRewinder.instance_variable_get(:@except)).to eq(['bars'])
      end

      it 'should create cleaner with options' do
        cleaner = DatabaseRewinder.instance_variable_get(:@cleaners).first
        expect(cleaner.instance_variable_get(:@only)).to eq(['foos'])
        expect(cleaner.instance_variable_get(:@except)).to eq(['bars'])
      end

      context 'call again with different options' do
        before do
          DatabaseRewinder.strategy = :truncate, { only: ['bazs'], except: [] }
        end

        it 'should overwrite options' do
          expect(DatabaseRewinder.instance_variable_get(:@only)).to eq(['bazs'])
          expect(DatabaseRewinder.instance_variable_get(:@except)).to eq([])
        end

        it 'should overwrite cleaner with new options' do
          cleaner = DatabaseRewinder.instance_variable_get(:@cleaners).first
          expect(cleaner.instance_variable_get(:@only)).to eq(['bazs'])
          expect(cleaner.instance_variable_get(:@except)).to eq([])
        end
      end
    end
  end
end
