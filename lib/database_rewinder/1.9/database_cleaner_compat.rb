# -*- coding: utf-8 -*-
module DatabaseRewinder
  module DatabaseCleanerCompat
    def start; end

    def strategy=(args)
      options = args.extract_options!
      @only, @except = options[:only], options[:except]
    end
  end
end
