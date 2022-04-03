defmodule ServerBench do
  use Application

  def start(_type, _args) do

    children = [
      {Store, nil},
      {Task.Supervisor, name: DumperSupervisor},
      {Dumper, nil},
      {Task.Supervisor, name: ClientSupervisor},
      {Task, fn -> Server.accept(8080) end}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
