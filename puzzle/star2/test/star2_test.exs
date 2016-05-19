defmodule Star2Test do
  use ExUnit.Case
  import Star2
  doctest Star2

  test "paper 2*3*4" do
    assert paper([2, 3, 4]) === 6 + 2 * (6 + 8 + 12)
  end

  test "normalize 2x3x4" do
    assert normalize_surface("2x3x4") == [2, 3, 4]
  end

  test "ribben 2x3x4" do
    assert ribben([2, 3, 4]) == 2 * (2 + 3) + (2 * 3 * 4)
  end
end
