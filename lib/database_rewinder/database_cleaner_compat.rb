module DatabaseRewinder
  module DatabaseCleanerCompat
    def start; end

    def strategy=(_strategy, only: nil, except: nil, **)
      @only, @except = only, except
    end
  end
end
