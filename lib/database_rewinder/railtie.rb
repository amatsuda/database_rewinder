require 'rails'

module DatabaseRewinder
  class Railtie < ::Rails::Railtie
    initializer 'database_rewinder', after: 'active_record.initialize_database' do
      ActiveSupport.on_load :active_record do
        DatabaseRewinder.init
        if RUBY_VERSION > '2.0.0'
          require_relative 'active_record_monkey'
        else
        require_relative '1.9.3/active_record_monkey'
        end
      end
    end
  end
end
