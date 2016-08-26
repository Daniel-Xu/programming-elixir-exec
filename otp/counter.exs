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
    new_val =
      receive do
        message -> proceess_message(current_val, message)
      end
    loop(new_val)
  end

  defp proceess_message(current_val, :inc) do
    current_val + 1
  end
  defp proceess_message(current_val, :dec) do
    current_val - 1
  end
  defp proceess_message(current_val, {:val, caller_pid, ref}) do
    send caller_pid, {ref, current_val}
    current_val
  end
end
