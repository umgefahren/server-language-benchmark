defmodule Server do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(ClientSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end


  defp serve(socket) do
    data = read_line(socket)
    command = ServerBench.Command.parse(data)
    execute_command(command, socket)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
    |> process_result(socket)
  end

  defp process_result({:ok, data}, _) do
    data
  end

  defp process_result({:error, _}, socket) do
    :gen_tcp.close(socket)
    ""
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  defp execute_command(%ServerBench.Command{type: :invalid, key: _, value: _, duration: _}, socket) do
    write_line("invalid command", socket)
  end

  defp execute_command(%ServerBench.Command{type: :get, key: key, value: _, duration: _}, socket) do
    Store.get(key)
    |> write_record(socket)
  end

  defp execute_command(%ServerBench.Command{type: :set, key: key, value: value, duration: _}, socket) do
    Store.get(key)
    |> write_record(socket)
    Store.set(key, value)
  end

  defp execute_command(%ServerBench.Command{type: :del, key: key, value: _, duration: _}, socket) do
    Store.del(key)
    |> write_record(socket)
  end

  defp execute_command(%ServerBench.Command{type: :get_counter, key: _, value: _, duration: _}, socket) do
    Store.get_counter()
    |> write_counter(socket)
  end

  defp execute_command(%ServerBench.Command{type: :set_counter, key: _, value: _, duration: _}, socket) do
    Store.set_counter()
    |> write_counter(socket)
  end

  defp execute_command(%ServerBench.Command{type: :del_counter, key: _, value: _, duration: _}, socket) do
    Store.del_counter()
    |> write_counter(socket)
  end

  defp execute_command(%ServerBench.Command{type: :new_dump, key: _, value: _, duration: _}, socket) do
    line = Dumper.new_dump()
    write_line("#{line}\n", socket)
  end

  defp execute_command(%ServerBench.Command{type: :get_dump, key: _, value: _, duration: _}, socket) do
    line = Dumper.get_dump()
    if line == nil do
      ^line = Dumper.new_dump()
    end
    write_line("#{line}\n", socket)
  end

  defp execute_command(%ServerBench.Command{type: :dump_interval, key: _, value: _, duration: duration}, socket) do
    Dumper.change_interval(duration)
    write_line("changed interval\n", socket)
  end

  defp execute_command(%ServerBench.Command{type: :set_ttl, key: key, value: value, duration: duration}, socket) do
    record = Store.get(key)
    Store.set(key, value)
    {:ok, _} = Task.start(__MODULE__, :kill_fun, [key, duration])
    write_record(record, socket)
  end

  defp write_counter(num, socket) do
    write_line("#{num}\n", socket)
  end

  defp write_record(nil, socket) do
    write_line("not found\n", socket)
  end

  defp write_record(record, socket) do
    write_line("#{record.value}\n", socket)
  end

  def kill_fun(key, timeout) do
    Process.sleep(timeout * 1000)
    Store.del(key)
  end
end
