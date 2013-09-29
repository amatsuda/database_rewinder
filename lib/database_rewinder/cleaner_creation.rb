module DatabaseRewinder
  module CleanerCreation
    def create_cleaner(connection_name)
      config = @db_config[connection_name] or raise %Q[Database configuration named "#{connection_name}" is not configured.]

      Cleaner.new(db: config['database'], connection_name: connection_name, only: @only, except: @except).tap {|c| @cleaners << c}
    end

    def [](_orm, connection: nil, **)
      if (cl = @cleaners.detect {|c| c.connection_name == connection})
        return cl
      end

      create_cleaner connection
    end
  end
end
