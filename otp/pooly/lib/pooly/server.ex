defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct sup: nil, worker_sup: nil, size: nil, workers: nil, mfa: nil, monitors: nil
  end

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker_pid) do
    GenServer.call(__MODULE__, {:checkin, worker_pid})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Callbacks

  # filter configuration
  def init([sup, pool_config]) when is_pid(sup) do
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
  end
  def init([{:mfa, mfa}|rest], state) do
    init(rest, %{state | mfa: mfa})
  end
  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end
  def init([_|rest], state) do
    init(rest, state)
  end
  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_info(:start_worker_supervisor, state = %{sup: sup, size: size, mfa: mfa}) do
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}
      [] ->
        {:reply, :noproc, state}
    end
  end
  def handle_call(:status, state = %{workers: workers, monitors: monitors}) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_cast({:checkin, worker_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, monitor_ref}] ->
        true = Process.demonitor(monitor_ref)
        true = :ets.delete(monitors, worker_pid)
        {:noreply, %{state | workers: [worker_pid|workers]}}
      [] ->
        {:noreply, state}
    end
  end

  # helpers
  defp supervisor_spec(mfa) do
    opts = [restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [mfa], opts)
  end

  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end
  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end
  defp prepopulate(size, sup, workers) do
    prepopulate(size - 1, sup, [new_worker(sup)|workers])
  end
  defp new_worker(sup) do
    # as our worker supervisor is configed as simple_one_for_one
    # here we just pass [] as term to start the child
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    worker
  end
end
