require "./record"

module ServerBenchmark
  class ConcurrentHashMap(K, V)
    ERR_KEY_NOT_FOUND = "not found"

    @mutex : Mutex = Mutex.new
    @h : Hash(K, V) = Hash(K, V).new

    def reset
      @mutex.synchronize do
        @h.clear
      end
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

    def dump
      String.build(256) do |s|
        s << '['

        @mutex.synchronize do
          last_idx = @h.size - 1
          @h.each_with_index do |(k, v), i|
            s << %({"key":")
            s << k
            s << %(","associated_value":{"value":")
            s << v.value
            s << %(","timestamp":")
            v.timestamp.to_rfc3339 s, fraction_digits: 6
            s << %("}})
            s << ',' unless i == last_idx
          end
        end
        s << ']'
      end
    end
  end
end
