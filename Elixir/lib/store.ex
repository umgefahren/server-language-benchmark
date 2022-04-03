defmodule Store do
  use GenServer

  defstruct content: %{}, get_counter: 0, set_counter: 0, del_counter: 0

  def start_link(d) do
    GenServer.start_link(__MODULE__, d, name: MyStore)
  end

  @impl true
  def init(_) do
    {:ok, %Store{}}
  end

  @impl true
  def handle_cast({:set, key, value}, %Store{content: con, get_counter: get_c, set_counter: set_c, del_counter: del_c}) do
    record = Record.new(key, value)
    new_map = Map.put(con, key, record)
    {:noreply, %Store{content: new_map, get_counter: get_c, set_counter: set_c + 1, del_counter: del_c}}
  end

  @impl true
  def handle_cast(_, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    content = Map.get(state, :content)
    record = Map.get(content, key)
    get_counter = Map.get(state, :get_counter)
    get_counter = get_counter + 1
    new_state = Map.put(state, :get_counter, get_counter)
    {:reply, record, new_state}
  end

  @impl true
  def handle_call({:del, key}, _from, state) do
    content = Map.get(state, :content)
    record = Map.get(content, key)
    new_content = Map.delete(content, key)
    del_counter = Map.get(state, :del_counter)
    new_state = Map.put(state, :content, new_content)
    new_state = Map.put(new_state, :del_counter, del_counter + 1)
    {:reply, record, new_state}
  end

  @impl true
  def handle_call(:del_counter, _from, state) do
    {:reply, Map.get(state, :del_counter), state}
  end

  @impl true
  def handle_call(:get_counter, _from, state) do
    {:reply, Map.get(state, :get_counter), state}
  end

  @impl true
  def handle_call(:set_counter, _from, state) do
    {:reply, Map.get(state, :set_counter), state}
  end

  @impl true
  def handle_call(:values, _from, state) do
    content = Map.get(state, :content)
    values = Map.values(content)
    {:reply, values, state}
  end

  @impl true
  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end

  @spec set(bitstring, bitstring) :: :ok
  def set(key, value) do
    GenServer.cast(MyStore, {:set, key, value})
  end

  @spec get(bitstring) :: Record | nil
  def get(key) do
    GenServer.call(MyStore, {:get, key})
  end

  def del(key) do
    GenServer.call(MyStore, {:del, key})
  end

  def get_counter() do
    GenServer.call(MyStore, :get_counter)
  end

  def set_counter() do
    GenServer.call(MyStore, :set_counter)
  end

  def del_counter() do
    GenServer.call(MyStore, :del_counter)
  end

  def values() do
    GenServer.call(MyStore, :values)
  end
end
