defmodule ThySupervisor do
  use GenServer
  # API
  def start_link(children_specs) do
    GenServer.start_link(__MODULE__, [children_specs])
  end

  def start_child(supervisor, child_spec) do
    GenServer.call(supervisor, {:start_child, child_spec})
  end

  def terminate_child(supervisor, pid) when is_pid(pid) do
    GenSever.call(supervisor, {:terminate_child, pid})
  end

  def restart_child(supervisor, pid, child_spec) do
    GenServer.call(supervisor, {:restart_child, pid, child_spec})
  end

  def count_children(supervisor) do
    GenServer.call(supervisor, :count_children)
  end

  def which_children(supervisor) do
    GenServer.call(supervisor, :which_children)
  end

  def terminate(_reason, state) do
    terminate_children(state)
    :ok
  end

  # Callbacks
  def init([children_specs]) do
    Process.flag(:trap_exit, true)
    state =
      children_specs
      |> start_children
      |> Enum.into(Map.new)

    {:ok, state}
  end

  def handle_call({:start_child, child_spec}, _from, state) do
    case start_child(child_spec) do
      {:ok, pid} ->
        new_state = Map.put(state, pid, child_spec)
        {:reply, {:ok, pid}, new_state}
      :error ->
        {:reply, {:error, "error starting child"}, state}
    end
  end
  def handle_call({:terminate_child, pid}, _from, state) do
    case terminate_child(pid) do
      :ok ->
        new_state = Map.delete(state, pid)
        {:reply, :ok, new_state}
      :error ->
        {:reply, {:error, "error terminating child"}, state}
    end
  end
  def handle_call({:restart_child, old_pid, child_spec}, _from, state) do
    with child_spec <- Map.get(state, old_pid),
         {:ok, {pid, child_spec}} <- restart_child(old_pid, child_spec) do

      new_state =
        state
        |> Map.delete(old_pid)
        |> Map.put(pid, child_spec)
      {:reply, {:ok, pid}, new_state}
    else
      :error -> {:reply, {:error, "error restarting child"}, state}
      _ -> {:reply, :ok, state}
    end
  end
  def handle_call(:count_children, _from, state) do
    {:reply, Map.size(state), state}
  end
  def handle_call(:which_children, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:EXIT, from, :killed}, state) do
    new_state = Map.delete(state, from)
    {:noreply, new_state}
  end
  def handle_info({:EXIT, from, :normal}, state) do
    new_state = Map.delete(state, from)
    {:noreply, new_state}
  end
  def handle_info({:EXIT, old_pid, _reason}, state) do
    with child_spec <- Map.get(state, old_pid),
         {:ok, {pid, child_spec}} <- restart_child(old_pid, child_spec) do

      new_state =
        state
        |> Map.delete(old_pid)
        |> Map.put(pid, child_spec)
      {:noreply, new_state}
    else
      _ -> {:noreply, state}
    end
  end

  # Helpers
  defp start_child({mod, fun, args}) do
    case apply(mod, fun, args) do
      pid when is_pid(pid) ->
        Process.link(pid)
        {:ok, pid}
      _ ->
        :error
    end
  end

  defp start_children([child_spec|rest]) do
    case start_child(child_spec) do
      {:ok, pid} ->
        [{pid, child_spec}|start_children(rest)]
      :error ->
        :error
    end
  end
  defp start_children([]), do: []

  defp restart_child(old_pid, child_spec) when is_pid(old_pid) do
    with :ok <- terminate_child(old_pid),
         {:ok, new_pid} <- start_child(child_spec),
      do: {:ok, {new_pid, child_spec}}
  end

  defp terminate_children(state) do
    Enum.each(state, fn {pid, _} ->
      terminate_child(pid)
    end)
  end
  defp terminate_children([]), do: :ok

  defp terminate_child(pid) do
    Process.exit(pid, :kill)
    :ok
  end
end
