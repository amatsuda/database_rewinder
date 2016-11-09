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


# models
class Foo < ActiveRecord::Base; end
class Bar < ActiveRecord::Base; end
class Baz < ActiveRecord::Base; end
class Quu < ActiveRecord::Base
  establish_connection "#{ENV['DB']}_2".to_sym
end

# migrations
class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:foos) {|t| t.string :name }
    create_table(:bars) {|t| t.string :name }
    create_table(:bazs) {|t| t.string :name }

    test2_connection = ActiveRecord::Base.establish_connection("#{ENV['DB']}_2".to_sym).connection
    test2_connection.create_table(:quus) {|t| t.string :name }
    ActiveRecord::Base.establish_connection ENV['DB'].to_sym
  end

  def self.down
    drop_table(:foos) {|t| t.string :name }
    drop_table(:bars) {|t| t.string :name }
    drop_table(:bazs) {|t| t.string :name }

    test2_connection = ActiveRecord::Base.establish_connection("#{ENV['DB']}_2".to_sym).connection
    test2_connection.drop_table :quus
    ActiveRecord::Base.establish_connection ENV['DB'].to_sym
  end
end
