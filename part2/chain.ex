defmodule Chain do
  def run(n) do
    IO.puts inspect :timer.tc(Chain, :create_process, [n])
  end

  def counter(send_to) do
    receive do
      n ->
        send send_to, n + 1
    end
  end

  def create_process(n) do
    last_pid = Enum.reduce(1..n, self, fn(_, previous_pid) ->
      spawn(Chain, :counter, [previous_pid])
    end)

    send last_pid, 0

    receive do
      final_result when is_integer(final_result) ->
        "Result is #{inspect(final_result)}"
    end
  end

end
