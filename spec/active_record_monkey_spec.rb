require 'spec_helper'

describe 'DatabaseRewinder::InsertRecorder#execute' do
  before do
    DatabaseRewinder.init
    Foo.create! name: 'foo1'
    Bar.connection.execute "insert into bars (name) values ('bar1')"
    DatabaseRewinder.cleaners
  end
  subject { DatabaseRewinder.instance_variable_get(:'@cleaners').detect {|c| c.db == 'test.sqlite3'} }

  describe '#inserted_tables' do
    subject { super().inserted_tables }
    it { should == %w(foos bars) }
  end

  describe '#pool' do
    subject { super().pool }
    it { should be }
  end
end
