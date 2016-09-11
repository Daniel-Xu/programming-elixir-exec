defmodule Pooly.TopSupervisor do
  use Supervisor

  def start_link(pools_config) do
    # start the supervisor process and link it to current process, e.g. iex
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children = [
      supervisor(Pooly.PoolsSupervisor, []),
      worker(Pooly.Server, [pools_config])
    ]
    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
