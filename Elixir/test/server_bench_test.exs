defmodule ServerBenchTest do
  use ExUnit.Case
  doctest ServerBench

  test "greets the world" do
    assert ServerBench.hello() == :world
  end
end
