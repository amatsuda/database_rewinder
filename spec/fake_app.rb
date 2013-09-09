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

# migrations
class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:foos) {|t| t.string :name }
    create_table(:bars) {|t| t.string :name }
    create_table(:bazs) {|t| t.string :name }
  end
end
