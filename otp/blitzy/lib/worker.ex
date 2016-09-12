defmodule Blitzy.Worker do
  use Timex
  require Logger

  def start(url) do
    {timestamp, result} = Duration.measure(fn -> HTTPoison.get(url) end)
    handle_response({Duration.to_milliseconds(timestamp), result})
  end

  defp handle_response({msecs, {:ok, %HTTPoison.Response{status_code: code}}})
    when code >= 200 and code <= 304 do
    Logger.info "worker [#{node} - #{inspect self}] completed in #{msecs} mesecs"
    {:ok, msecs}
  end
  defp handle_response({_msecs, %HTTPoison.Error{reason: reason}}) do
    Logger.info "worker [#{node} - #{inspect self}] error due to #{reason}"
    {:error, reason}
  end
  defp handle_response({_msecs, _reason}) do
    Logger.info "worker [#{node} - #{inspect self}] error out"
    {:error, :unknown}
  end
end
