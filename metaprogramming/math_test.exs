defmodule MathTest do
  use Assertion

  test "integers can be added and subtracted" do
    assert 1 + 1 == 2
    assert 2 + 3 == 5
    assert 5 - 4 == 1
  end

  test "integers can be multiplied" do
    assert 1 * 1 == 2
  end
end
