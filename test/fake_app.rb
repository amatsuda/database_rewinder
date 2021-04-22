# frozen_string_literal: true

ENV['DB'] ||= 'sqlite3'
require 'active_record/railtie'

module DatabaseRewinderTestApp
  Application = Class.new(Rails::Application) do
    # Rais.root
    config.root = __dir__

    config.eager_load = false
    config.active_support.deprecation = :log
  end.initialize!
end

load 'active_record/railties/databases.rake'

require 'active_record/base'
ActiveRecord::Tasks::DatabaseTasks.root ||= Rails.root
ActiveRecord::Tasks::DatabaseTasks.drop_current 'test'
ActiveRecord::Tasks::DatabaseTasks.drop_current 'test2'
ActiveRecord::Tasks::DatabaseTasks.create_current 'test'
ActiveRecord::Tasks::DatabaseTasks.create_current 'test2'

# models
class Foo < ActiveRecord::Base; end
class Bar < ActiveRecord::Base; end
class Baz < ActiveRecord::Base; end
class Quu < ActiveRecord::Base
  establish_connection :test2
end

# migrations
class CreateAllTables < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.establish_connection :test
    create_table(:bars) {|t| t.string :name; t.index :name, unique: true }
    create_table(:foos) {|t| t.string :name; t.references :bar, foreign_key: true }
    create_table(:bazs) {|t| t.string :name }

    test2_connection = ActiveRecord::Base.establish_connection(:test2).connection
    test2_connection.create_table(:quus) {|t| t.string :name }
    ActiveRecord::Base.establish_connection :test
  end

  def self.down
    drop_table(:foos) {|t| t.string :name }
    drop_table(:bars) {|t| t.string :name }
    drop_table(:bazs) {|t| t.string :name }

    test2_connection = ActiveRecord::Base.establish_connection(:test2).connection
    test2_connection.drop_table :quus
    ActiveRecord::Base.establish_connection :test
  end
end
