defmodule Record do
  defstruct key: nil, value: nil, timestamp: nil

  def new(key, value) when is_bitstring(key) and is_bitstring(value) do
    timestamp = DateTime.utc_now()
    %Record{key: key, value: value, timestamp: timestamp}
  end
end
