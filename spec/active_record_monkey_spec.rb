require 'spec_helper'

describe 'DatabaseRewinder::InsertRecorder#execute' do
  before do
    DatabaseRewinder.init
    Foo.create! name: 'foo1'
    Bar.create! name: 'bar1'
    DatabaseRewinder.cleaners
  end
  subject { DatabaseRewinder.instance_variable_get(:'@cleaners').detect {|c| c.db == ':memory:'} }
  its(:inserted_tables) { should == %w(foos bars) }
  its(:pool) { should be }
end
