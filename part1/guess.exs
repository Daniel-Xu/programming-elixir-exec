defmodule Chop do
  # we have a header without body
  def guess(number, range \\ 1..1000)

  def guess(number, range = low..high)  do
    guess = div(low + high, 2)
    IO.puts "is it #{guess}"
    _guess(number, guess, range)
  end

  defp _guess(number, number, _) do
    IO.puts "it #{number}"
  end

  defp _guess(number, gs, _..high) when number > gs do
    start = gs + 1
    guess(number, start..high)
  end

  defp _guess(number, gs, low.._) when number < gs do
    endn = gs - 1
    guess(number, low..endn)
  end
end
