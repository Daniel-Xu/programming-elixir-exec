defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect/1)

    args
    |> parse_args()
    |> process_options([node|Node.list()])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests], strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], []} ->
        do_requests(n, url, nodes)
      _ ->
        do_help
    end
  end

  defp do_requests(n, url, nodes) do
    Logger.info "Pummelling #{url} with #{n} requests"
    total_nodes = Enum.count(nodes)
    req_per_node = div(n, total_nodes)

    nodes
    |> Enum.flat_map(fn node ->
         Enum.map(1..req_per_node, fn _ ->
           Task.Supervisor.async({Blitzy.TasksSupervisor, node}, Blitzy.Worker, :start, [url])
         end)
       end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results()
  end

  defp do_help do
    IO.puts """
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n, [--requests] # Number of requests

    Example:
    ./blitzy -n 100 http://www.bieberfever.com
    """
    System.halt(0)
  end

  defp parse_results(results) do
    {successes, _failures} =
      results
      |> Enum.partition(fn result ->
        case result do
          {:ok, _} -> true
          _ -> false
        end
      end)

      total_workers = length(results)
      total_success = length(successes)
      total_failures = total_workers - total_success
      data = Enum.map(successes, fn {:ok, time} -> time end)
      average_time = average(data)
      longest_time = Enum.max(data)
      shortest_time = Enum.min(data)

      IO.puts """

      Total workers    : #{total_workers}
      Successful reqs  : #{total_success}
      Failed res       : #{total_failures}
      Average (msecs)  : #{average_time} ms
      Longest (msecs)  : #{longest_time} ms
      Shortest (msecs) : #{shortest_time} ms
      """
  end

  defp average(time_list) do
    sum = Enum.sum(time_list)
    if sum > 0 do
      sum / Enum.count(time_list)
    else
      0
    end
  end
end
