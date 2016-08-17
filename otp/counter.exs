defmodule Counter do

  def inc(pid) do
    send(pid, :inc)
  end

  def dec(pid) do
    send(pid, :dec)
  end

  def val(pid, timeout \\ 5000) do
    ref = make_ref()
    send(pid, {:val, self(), ref})

    receive do
      {^ref, val} -> val
    after timeout -> exit(:timeout)
    end
  end

  def start_link(initial_val) do
    {:ok, spawn_link(fn -> loop(initial_val) end)}
  end


  defp loop(current_val) do
    new_val = receive do
      :inc -> current_val + 1
      :dec -> current_val - 1
      {:val, caller_pid, ref} ->
        send caller_pid, {ref, current_val}
        current_val
    end
    loop(new_val)
  end

end
