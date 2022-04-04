require 'date'

class Record
  @key
  @value
  @timestamp

  def initialize(key, value)
    @key = key
    @value = value
    @timestamp = DateTime.now
  end

  def key
    @key
  end

  def value
    @value
  end

  def timestamp
    @timestamp
  end

  def to_s
    "#{@key} #{@value} #{@timestamp}"
  end
end
