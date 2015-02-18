ENV['RAILS_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require 'rails'
require 'database_rewinder'
require 'fake_app'

RSpec.configure do |config|
  config.before :all do
    CreateAllTables.up unless ActiveRecord::Base.connection.table_exists? 'foos'
  end
  config.after :each do
    [Foo, Bar, Baz, Quu].each {|m| m.delete_all }
  end
end
