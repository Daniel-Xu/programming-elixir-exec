defmodule FibSolver do
  def fib(client_id) do
    send(client_id, {:ready, self})

    receive do
      {:fib, n, client_id} ->
        send(client_id, {:answer, n, fib_calc(n), self})
        fib(client_id)
      {:shutdown} ->
        exit(:normal)
    end
  end

  defp fib_calc(0), do: 0
  defp fib_calc(1), do: 1
  defp fib_calc(n), do: fib_calc(n-2) + fib_calc(n-1)
end

defmodule FibClient do
  def run(process_num, module_name, fun, to_calc) do
    (1..process_num)
    |> Enum.map(fn(_) -> spawn(module_name, fun, [self]) end)
    |> schedule_work(to_calc, [])

  end

  def schedule_work(processes, queue, results) do
    receive do
      {:ready, server_id} when length(queue) > 0 ->
        [next | tail] = queue
        send(server_id, {:fib, next, self})
        schedule_work(processes, tail, results)

      {:ready, server_id} ->
        send(server_id, {:shutdown})
        if length(processes) > 1 do
          schedule_work(List.delete(processes, server_id), queue, results)
        else
          Enum.sort(results, fn({n1, _}, {n2, _}) -> n1 <= n2 end)
        end
      {:answer, n, result, _server_id} ->
        schedule_work(processes, queue, [ {n, result} | results])
    end

  end
end

to_calc = [ 37, 37, 37, 37, 37, 37 ]
Enum.each 1..10, fn(num_process) ->
  {time, result} = :timer.tc(FibClient, :run, [num_process, FibSolver, :fib, to_calc])

  if num_process == 1 do
    IO.puts inspect result
    IO.puts "\n #   time (s)"
  end
  :io.format "~2B      ~.2f~n", [num_process, time/1000000.0]
end
