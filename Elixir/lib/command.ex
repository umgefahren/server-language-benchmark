defmodule ServerBench.Command do
  @enforce_keys [:type]
  defstruct [:type, key: nil, value: nil, duration: nil]
  def string_valid?(input) do
    regexp = ~r/[a-zA-Z0-9]+/
    Regex.match?(regexp, input)
  end

  def parse(input) when is_bitstring(input) do
    String.trim(input)
    |> String.split()
    |> parse()
  end

  def parse(["GET", key]) do
    if string_valid?(key) do
      %ServerBench.Command{type: :get, key: key}
    else
      %ServerBench.Command{type: :invalid}
    end
  end

  def parse(["SET", key, value]) do
    if string_valid?(key) && string_valid?(value) do
      %ServerBench.Command{type: :set, key: key, value: value}
    else
      %ServerBench.Command{type: :invalid}
    end
  end

  def parse(["DEL", key]) do
    if string_valid?(key) do
      %ServerBench.Command{type: :del, key: key}
    else
      %ServerBench.Command{type: :invalid}
    end
  end

  def parse(["GETC"]) do
    %ServerBench.Command{type: :get_counter}
  end

  def parse(["SETC"]) do
    %ServerBench.Command{type: :set_counter}
  end

  def parse(["DELC"]) do
    %ServerBench.Command{type: :del_counter}
  end

  def parse(["GETDUMP"]) do
    %ServerBench.Command{type: :get_dump}
  end

  def parse(["NEWDUMP"]) do
    %ServerBench.Command{type: :new_dump}
  end

  def parse(["DUMPINTERVAL", timestamp]) when is_bitstring(timestamp) do
    parse(["DUMPINTERVAL", parse_time(timestamp)])
  end

  def parse(["DUMPINTERVAL", nil]) do
    %ServerBench.Command{type: :invalid}
  end

  def parse(["DUMPINTERVAL", [_, hours, minutes, seconds]]) do
    time = calc_time(String.to_integer(hours), String.to_integer(minutes), String.to_integer(seconds))
    %ServerBench.Command{type: :dump_interval, duration: time}
  end

  def parse(["SETTTL", key, value, timestamp]) when is_bitstring(timestamp) do
    if string_valid?(key) && string_valid?(value) do
      parse(["SETTTL", key, value, parse_time(timestamp)])
    else

      %ServerBench.Command{type: :invalid}
    end
  end

  def parse(["SETTTL", _, _, nil]) do
    %ServerBench.Command{type: :invalid}
  end

  def parse(["SETTTL", key, value, [_, hours, minutes, seconds]]) do
    %ServerBench.Command{type: :set_ttl, key: key, value: value, duration: calc_time(String.to_integer(hours), String.to_integer(minutes), String.to_integer(seconds))}
  end

  def parse(_) do
    %ServerBench.Command{type: :invalid}
  end

  def parse_time(input) when is_bitstring(input) do
    time_regex = ~r/([0-9][0-9])h-([0-9][0-9])m-([0-9][0-9])s/
    matches = Regex.run(time_regex, String.trim(input))
    matches
  end

  def parse_time(_) do
    IO.puts "Time parse failed"
  end

  def calc_time(hours, minutes, seconds) do
    ret = seconds
    ret = ret + (minutes * 60)
    ret + (hours * 60 * 60)
  end
end
