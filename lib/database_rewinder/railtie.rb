module DatabaseRewinder
  class Railtie < ::Rails::Railtie
    initializer 'database_rewinder', after: 'active_record.initialize_database' do
      ActiveSupport.on_load :active_record do
        DatabaseRewinder.init
        DatabaseRewinder.db_config = Rails.application.config.database_configuration
        require_relative 'active_record_monkey'
      end
    end
  end
end
