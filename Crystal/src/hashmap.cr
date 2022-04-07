require "./record"

module ServerBenchmark
  class ConcurrentHashMap(K, V)
    ERR_KEY_NOT_FOUND = "not found"

    @mutex : Mutex = Mutex.new
    @h : Hash(K, V) = Hash(K, V).new

    def initialize()
    end

    def [](key)
      v : V? = nil

      @mutex.synchronize do
        v = @h[key]?
      end

      v || ERR_KEY_NOT_FOUND
    end

    def []=(key, val : String)
      v : V? = nil

      rec = Record.new val, Time.utc

      @mutex.synchronize do
        v = @h[key]?
        @h[key] = rec
      end

      v || ERR_KEY_NOT_FOUND
    end

    def delete(key)
      v : V? = nil

      @mutex.synchronize do
        v = @h.delete(key)
      end

      v || ERR_KEY_NOT_FOUND
    end
  end
end
