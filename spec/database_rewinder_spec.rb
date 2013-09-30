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

  describe '.strategy=' do
    context 'when no option is specified' do
      before { described_class.strategy = :truncate }
      it 'should set strategy' do
        expect(described_class.instance_variable_get(:@only)).to be_nil
        expect(described_class.instance_variable_get(:@except)).to be_nil
      end
    end

    context 'when only option is specified' do
      before { described_class.strategy = :truncate, { only: %w{foos} } }
      it 'should set only option' do
        expect(described_class.instance_variable_get(:@only)).to eq(['foos'])
        expect(described_class.instance_variable_get(:@except)).to be_nil
      end
    end

    context 'when except option is specified' do
      before { described_class.strategy = :truncate, { except: %w{foos} } }
      it 'should set except option' do
        expect(described_class.instance_variable_get(:@only)).to be_nil
        expect(described_class.instance_variable_get(:@except)).to eq(['foos'])
      end
    end

    context 'when only and except option are specified' do
      before { described_class.strategy = :truncate, { only: %w{foos}, except: %w{bars} } }
      it 'should set only and except options' do
        expect(described_class.instance_variable_get(:@only)).to eq(['foos'])
        expect(described_class.instance_variable_get(:@except)).to eq(['bars'])
      end
    end
  end
end
