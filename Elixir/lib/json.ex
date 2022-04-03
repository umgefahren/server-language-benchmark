defmodule Json.Super do
  @derive [Poison.Encoder]
  defstruct [:key, :associated_value]

  def new(record) do
    associated_value = Json.Sub.new(record)
    %Json.Super{key: record.key, associated_value: associated_value}
  end
end

defmodule Json.Sub do
  @derive [Poison.Encoder]
  defstruct [:value, :timestamp]

  def new(record) do
    %Json.Sub{value: record.value, timestamp: record.timestamp}
  end
end
