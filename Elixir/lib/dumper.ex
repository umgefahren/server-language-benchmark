defmodule Dumper do
  use GenServer

  defstruct dump_value: "[]", dump_interval: 10, dumper: nil

  def start_link(d) do
    GenServer.start_link(__MODULE__, d, name: MyDumper)
  end

  @impl true
  def init(_) do
    {:ok, dumper} = Task.Supervisor.start_child(DumperSupervisor,__MODULE__, :dumping_fun, [10])
    {:ok, %Dumper{dumper: dumper}}
  end

  @impl true
  def handle_call(:new_dump, _from, state) do
    json_string = Store.values()
      |> Enum.map(fn record -> Json.Super.new(record) end)
      |> Poison.encode!()
    state = Map.put(state, :dump_value, json_string)
    {:reply, json_string, state}
  end

  @impl true
  def handle_call(:get_dump, _from, state) do
    json_string = Map.get(state, :dump_value)
    {:reply, json_string, state}
  end

  @impl true
  def handle_cast({:change_interval, interval}, state) do
    state = Map.put(state, :dump_interval, interval)
    current_dumper = Map.get(state, :dumper)
    Task.Supervisor.terminate_child(DumperSupervisor, current_dumper)
    {:ok, dumper} = Task.Supervisor.start_child(DumperSupervisor,__MODULE__, :dumping_fun, [10])
    new_state = Map.put(state, :dumper, dumper)
    {:noreply, new_state}
  end

  def new_dump() do
    GenServer.call(MyDumper, :new_dump)
  end

  def get_dump() do
    GenServer.call(MyDumper, :get_dump)
  end

  def change_interval(time_interval) do
    GenServer.cast(MyDumper, {:change_interval, time_interval})
  end

  def dumping_fun(time_interval) do
    Process.sleep(time_interval * 1000)
    Dumper.new_dump()
    dumping_fun(time_interval)
  end
end
