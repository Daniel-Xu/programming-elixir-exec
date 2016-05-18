defmodule Star1Test do
  use ExUnit.Case
  import Star1, only: [calculate_path: 1]

  doctest Star1

  test "0 floor" do
    assert calculate_path('(()())')== 0
  end
  test "positive floor number" do
    assert calculate_path('()())')== -1
  end
  test "negative floor number" do
    assert calculate_path('((()((')== 4
  end
end
