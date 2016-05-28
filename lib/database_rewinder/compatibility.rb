module DatabaseRewinder
  module Compatibility
    def clean_with(*args)
      cleaners.each {|c| c.clean_with(*args)}
    end

    def cleaning(&block)
      begin
        yield
      ensure
        clean
      end
    end

    def start; end

    def strategy=(args)
      options = args.is_a?(Array) ? args.extract_options! : {}
      @only, @except = options[:only], options[:except]
      cleaners.each {|c| c.strategy = nil, options}
    end

    # In order to add another database to cleanup, you can give its connection name in one of the forms below:
    #
    #    # the simplest form
    #    DatabaseRewinder['the_db_name']
    #
    # or
    #
    #    # with connection: key
    #    DatabaseRewinder[connection: 'the_db_name']
    #
    # or
    #
    #    # DatabaseCleaner compatible
    #    DatabaseRewinder[:active_record, connection: 'the_db_name']
    #
    # You can cleanup multiple databases for each test using this configuration.
    def [](orm, connection: nil, **)
      if connection.nil?
        if orm.is_a? String
          connection = orm
        elsif orm.is_a?(Hash) && orm.has_key?(:connection)
          connection = orm[:connection]
        end
      end
      super connection
    end
  end
  class << self
    prepend Compatibility
  end

  class Cleaner
    module Compatibility
      def clean_with(_strategy, only: nil, except: nil, **)
        originals = @only, @except
        self.only, self.except = Array(only), Array(except)
        clean_all
      ensure
        self.only, self.except = originals
      end

      def strategy=(args)
        options = args.is_a?(Array) ? args.extract_options! : {}
        self.only = Array(options[:only]) if options.key?(:only)
        self.except = Array(options[:except]) if options.key?(:except)
      end
    end

    include Compatibility
  end
end
