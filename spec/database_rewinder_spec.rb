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
end
