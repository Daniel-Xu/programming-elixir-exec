defmodule Weather.Worker do
  use GenServer

  @name WW
  # client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  def reset_stats do
    GenServer.cast(@name, :reset_stats)
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  # server API
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:location, location}, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{temp} °C", new_stats}
      _ ->
        {:reply, :error, stats}
    end
  end
  def handle_call(:get_stats, _from, stats) do
    {:reply, stats, stats}
  end

  def handle_cast(:reset_stats, stats) do
    {:noreply, %{}}
  end
  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  def terminate(reason, stats) do
    IO.puts "Server terminated because of #{inspect reason}"
    IO.inspect(stats)
  end

  # helper API
  defp apikey do
    "e73528b8d07ffc4a1705204af4593a17"
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&APPID=#{apikey}"
  end

  def temperature_of(location) do
    location
    |> url_for()
    |> HTTPoison.get()
    |> parse_response()
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> Poison.Parser.parse!()
    |> compute_temperature()
  end
  defp parse_response(_resp) do
    :error
  end

  defp compute_temperature(data) do
    IO.inspect data["sys"]["country"]
    try do
      temp =
        (data["main"]["temp"] - 273.15)
        |> Float.round(1)
        |> Float.to_string()
      {:ok, data["sys"]["country"] <> " " <>temp}
    rescue
      _ -> :error
    end
  end

  defp update_stats(stats, location) do
    Map.update(stats, location, 1, &(&1 + 1))
  end
end
