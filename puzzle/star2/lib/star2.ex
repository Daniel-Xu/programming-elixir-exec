defmodule Star2 do

  def normalize_surface(input) do
    Enum.map(input |> String.split("x"), fn(str) -> String.to_integer(str) end)
  end

  def paper([a, b, c]) do
    surface = [a * b, a * c, b * c]
    leastSurface = Enum.min(surface)

    leastSurface + 2 * Enum.reduce(surface, &(&1 + &2))
  end

  def stream_file(name) do
    name
    |> File.stream!
    |> IO.inspect
    |> Stream.map(&String.strip/1)
    |> Stream.map(&normalize_surface/1)
    |> Stream.map(&paper/1)
    |> Enum.reduce(&(&1 + &2))
  end

end


