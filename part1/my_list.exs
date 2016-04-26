defmodule MyList do
  def len([]) do
    0
  end

  def len([_head | tail]) do
    1 + len(tail)
  end

  def squre([]), do: []
  def build([head | tail]), do: [head * head | squre(tail)]

  def add_1([]), do: []
  def add_1([head | tail]), do: [head + 1 | add_1(tail)]

  def s_map([], _), do: []
  def s_map([head | tail], fun), do: [fun.(head) | s_map(tail, fun)]

  def sum([], total\\0), do: total
  def sum([head | tail], total), do: sum(tail, head + total)

  def reduce([], acc, _), do: acc
  def reduce([head | tail], acc, fun), do: reduce(tail, fun.(acc, head), fun)

  # map sum
  def map_sum([], _fun), do: 0
  def map_sum([head|tail], fun), do: fun.(head) + map_sum(tail, fun)

  # max list
  def max([x]), do: x
  def max([head|tail]), do: Kernel.max(head, max(tail))

  # span 2->5: [2 3 4 5]
  def span(f, t) do
    [f | span(f+1, t)]
  end
  def span(f, t) when f > t do
    []
  end
end
