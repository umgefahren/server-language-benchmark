module ServerBenchmark
  class Dump
    @current : Atomic(String)
    @interval : Time::Span
    @interval_dump_fiber : Fiber
    def initialize(@hashmap : ConcurrentHashMap(String, Record))
      @current = Atomic(String).new ""
      dump
      @interval = Time::Span.new seconds: 10
      @interval_dump_fiber = spawn name: "Dump Interval" { interval_dump }
    end

    def dump
      @current.set @hashmap.dump
    end

    def get
      @current.get
    end

    def set_interval(interval)
      @interval = interval
      Fiber.current.enqueue
      @interval_dump_fiber.resume
    end

    private def interval_dump
      loop do
        sleep @interval
        dump
      end
    end
  end
end
