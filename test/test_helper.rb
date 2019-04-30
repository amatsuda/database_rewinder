# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require 'rails'
require 'active_record'
require 'database_rewinder'
require 'fake_app'
require 'test/unit/rails/test_help'
begin
  require 'selenium/webdriver'  # rails 6
rescue LoadError
end

migrated = ActiveRecord::Base.connection.respond_to?(:data_source_exists?) ? ActiveRecord::Base.connection.data_source_exists?('foos') : ActiveRecord::Base.connection.table_exists?('foos')
CreateAllTables.up unless migrated

module DeleteAllTables
  def teardown
    super
    [Foo, Bar, Baz, Quu].each {|m| m.delete_all }
  end
end
ActiveSupport::TestCase.send :prepend, DeleteAllTables
