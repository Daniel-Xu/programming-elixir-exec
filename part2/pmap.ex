defmodule Parallel do
  def pmap(collection, fun) do
    current = self
    collection
    |> Enum.map(
      fn(elem) ->
        spawn_link(fn -> send(current, {self, fun.(elem)}) end)
      end)

    |> Enum.map(
      fn(pid) ->
        receive do
          {^pid, result} ->
            result
        end
      end)
  end
end
