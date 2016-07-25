defmodule Parallel do
  import :timer, only: [ sleep: 1 ]

  def pmap(collection, fun) do
    current = self
    collection
    |> Enum.map(
      fn(elem) ->
        spawn_link(
          fn ->
            sleep Enum.random([1, 2, 3]) * 100
            send(current, {self, fun.(elem)})
          end)
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
