module ServerBenchmark
  struct Record
    property value : String
    property timestamp : Time

    def initialize(v, t)
      @value = v
      @timestamp = t
    end

    def to_s(io)
      io << @value
    end
  end
end
