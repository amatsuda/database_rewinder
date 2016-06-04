ENV['RAILS_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require 'rails'
require 'active_record'
require 'database_rewinder'
require 'fake_app'
require 'test/unit/rails/test_help'

CreateAllTables.up unless ActiveRecord::Base.connection.table_exists? 'foos'

module DeleteAllTables
  def teardown
    super
    [Foo, Bar, Baz, Quu].each {|m| m.delete_all }
  end
end
ActiveSupport::TestCase.prepend DeleteAllTables
