GET_STRING = 'GET'
SET_STRING = 'SET'
DEL_STRING = 'DEL'
GET_COUNTER_STRING = 'GETC'
SET_COUNTER_STRING = 'SETC'
DEL_COUNTER_STRING = 'DELC'
GET_DUMP_STRING = 'GETDUMP'
NEW_DUMP_STRING = 'NEWDUMP'
DUMP_INTERVAL_STRING = 'DUMPINTERVAL'
SET_TTL_STRING = 'SETTTL'

VALUE_REGEX = Regexp.new "[a-zA-Z0-9]+"
TIME_REGEX = Regexp.new "([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9])s"

module Parsing
  def parse_type(part)
    case part
    when GET_STRING
      return :get
    when SET_STRING
      return :set
    when DEL_STRING
      return :del
    when GET_COUNTER_STRING
      return :get_counter
    when SET_COUNTER_STRING
      return :set_counter
    when DEL_COUNTER_STRING
      return :del_counter
    when GET_DUMP_STRING
      return :get_dump
    when NEW_DUMP_STRING
      return :new_dump
    when DUMP_INTERVAL_STRING
      return :dump_interval
    when SET_TTL_STRING
      return :set_ttl
    else
      return :invalid
    end
  end

  def validate_string(input)
    VALUE_REGEX.match(input) != nil
  end

  def parse_time(input)
    match_result = TIME_REGEX.match input
    if match_result == nil
      return nil
    end

    hours_string = match_result[0]
    minutes_string = match_result[1]
    seconds_string = match_result[2]
    hours = hours_string.to_i
    minutes = minutes_string.to_i
    seconds = seconds_string.to_i
    seconds += minutes * 60
    seconds += hours * 60 * 60
    seconds
  end

  def parse_command(line)
    if line == nil
      command = Command.new
      command.type = :invalid
      return command
    end
    parts = line.split ' '
    if parts.length < 1
      return nil
    end

    command = Command.new

    type_string = parts[0]

    command.type = parse_type type_string

    if command.type == :invalid
      return nil
    end


    case command.type
    when :get
      if parts.length != 2
        return nil
      end
      key_string = parts[1]
      unless validate_string(key_string)
        return nil
      end
      command.key = key_string
    when :set
      if parts.length != 3
        return nil
      end
      key_string = parts[1]
      unless validate_string(key_string)
        return nil
      end
      command.key = key_string
      value_string = parts[2]
      unless validate_string value_string
        return nil
      end
      command.value = value_string
    when :del
      if parts.length != 2
        return nil
      end
      key_string = parts[1]
      unless validate_string key_string
        return nil
      end
      command.key = key_string
    when :get_counter
      if parts.length != 1
        return nil
      end
    when :set_counter
      if parts.length != 1
        return nil
      end
    when :del_counter
      if parts.length != 1
        return nil
      end
    when :get_dump
      if parts.length != 1
        return nil
      end
    when :new_dump
      if parts.length != 1
        return nil
      end
    when :dump_interval
      if parts.length != 2
        return nil
      end

      time = parse_time parts[1]
      if time == nil
        return nil
      end
      command.time = time
    when :set_ttl
      if parts.length != 4
        return nil
      end
      key_string = parts[1]
      unless validate_string key_string
        return nil
      end
      value_string = parts[2]
      unless validate_string value_string
        return nil
      end
      time_string = parts[3]
      time = parse_time time_string
      if time == nil
        return nil
      end
      command.key = key_string
      command.value = value_string
      command.time = time
    else
      return nil
    end

    command
  end
end



class Command
  @type
  @key
  @value
  @time

  def initialize(type = :invalid, key = nil, value = nil, time = nil)
    @type = type
    @key = key
    @value = value
    @time = time
  end

  attr_accessor :type, :key, :value, :time

  def to_s
    "#{@type} #{@key} #{@value} #{@time}"
  end
end
