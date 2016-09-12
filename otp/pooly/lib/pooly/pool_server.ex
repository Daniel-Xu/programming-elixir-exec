defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct pool_sup: nil, worker_sup: nil, size: nil, workers: nil, mfa: nil,
      monitors: nil, name: nil, overflow: nil, max_overflow: nil, waiting: nil
  end

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def checkout(pool_name, block, timeout) do
    GenServer.call(name(pool_name), {:checkout, block}, timeout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.call(name(pool_name), {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Callbacks

  # filter configuration
  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new()
    init(pool_config, %State{pool_sup: pool_sup, monitors: monitors, waiting: waiting, overflow: 0})
  end
  def init([{:name, name}|rest], state) do
    init(rest, %{state | name: name})
  end
  def init([{:mfa, mfa}|rest], state) do
    init(rest, %{state | mfa: mfa})
  end
  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end
  def init([{:max_overflow, max_overflow}|rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end
  def init([_|rest], state) do
    init(rest, state)
  end
  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_info(:start_worker_supervisor, state = %{pool_sup: pool_sup, size: size, mfa: mfa, name: name}) do
    # start woker supervisor
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, supervisor_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end
  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    #consumer down
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid|workers]}
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, worker_sup, reason}, state = %{worker_sup: worker_sup}) do
    {:stop, reason, state}
  end
  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers, pool_sup: pool_sup}) do
    # worker down
    # worker is restarted by supervisor but will be not included into pool server

    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_worker_exit(pid, state)
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_call({:checkout, block},
    customer = {from_pid, _ref},
    %{workers: workers,
      worker_sup: worker_sup,
      monitors: monitors,
      waiting: waiting,
      overflow: overflow,
      max_overflow: max_overflow} = state) do

    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}
      [] when max_overflow > 0 and overflow < max_overflow ->
        {worker, ref} = new_worker(worker_sup, from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | overflow: overflow + 1}}
      [] when block == true ->
        ref = Process.monitor(from_pid)
        # notice that: customer here is the whole client, not just pid
        waiting = :queue.in({customer, ref}, waiting)
        {:noreply, %{state | waiting: waiting}, :infinity}
      [] ->
        {:reply, :full, state}
    end
  end
  def handle_call(:status, state = %{workers: workers, monitors: monitors}) do
    {:reply, {state_name(state), length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_cast({:checkin, worker_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, monitor_ref}] ->
        true = Process.demonitor(monitor_ref)
        true = :ets.delete(monitors, worker_pid)
        new_state = handle_checkin(worker_pid, state)
        {:noreply, new_state}
      [] ->
        {:noreply, state}
    end
  end

  # helpers

  defp handle_checkin(pid, state) do
    %{worker_sup:   worker_sup,
      workers:      workers,
      monitors:     monitors,
      waiting:      waiting,
      overflow:     overflow} = state

    case :queue.out(waiting) do
      {{:value, {customer, monitor_ref}}, left} ->
        # worker and customer pair
        true = :ets.insert(monitors, {pid, monitor_ref})
        GenServer.reply(customer, pid)
        %{state | waiting: left}
      {:empty, empty} when overflow > 0 ->
        :ok = dismiss_worker(worker_sup, pid)
        %{state | waiting: empty, overflow: overflow - 1}
      {:empty, empty} ->
        %{state | workers: [pid|workers], waiting: empty, overflow: 0}
    end
  end

  defp dismiss_worker(worker_sup, pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(worker_sup, pid)
  end

  defp handle_worker_exit(pid, state) do
    %{worker_sup:   worker_sup,
      workers:      workers,
      waiting:      waiting,
      monitors:     monitors,
      overflow:     overflow} = state

    case :queue.out(waiting) do
      {{:value, {customer, ref}}, left} ->
        new_worker = new_worker(worker_sup)
        true = :ets.insert(monitors, {new_worker, ref})

        GenServer.reply(customer, new_worker)
        %{state | waiting: left}
      {:empty, empty} when overflow > 0 ->
        %{state | overflow: overflow - 1, waiting: empty}
      {:empty, empty} ->
        %{state | workers: [new_worker(worker_sup)|workers], waiting: empty}
    end
  end

  defp supervisor_spec(name, mfa) do
    # NOTE: The reason this is set to temporary is because the WorkerSupervisor
    #       is started by the PoolServer.
    opts = [id: name <> "WorkerSupervisor", shutdown: 10000, restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [self(), mfa], opts)
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
    Process.link(worker)
    worker
  end
  defp new_worker(sup, from_pid) do
    pid = new_worker(sup)
    ref = Process.monitor(from_pid)
    {pid, ref}
  end

  defp name(pool_name) do
    :"#{pool_name}Server"
  end

  defp state_name(%State{workers: workers,
                         overflow: overflow,
                         max_overflow: max_overflow}) when overflow < 1 do
    # overflow == 0 && worker == 0
    case length(workers) == 0 do
      true ->
       :full
        if max_overflow < 1 do
          :full
        else
          :overflow
        end
      false ->
        :ready
    end
  end
  defp state_name(%State{overflow: max_overflow, max_overflow: max_overflow}) do
    :full
  end
  defp state_name(_state) do
    :overflow
  end
end
