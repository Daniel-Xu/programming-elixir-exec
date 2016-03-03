fiz_buz_cal = fn
  0, 0, _ -> :FizzBuzz
  0, _, _ -> :Fizz
  _, 0, _ -> :Buzz
  _, _, c -> c
end
IO.puts fiz_buz_cal.(0, 0, 1)
IO.puts fiz_buz_cal.(1, 0, 1)
IO.puts fiz_buz_cal.(1, 0, 0)
IO.puts fiz_buz_cal.(0, 0, 0)
IO.puts fiz_buz_cal.(0, 0, 0)

fiz_buz = fn n ->
  fiz_buz_cal.(rem(n, 3), rem(n, 5), n)
end

IO.puts fiz_buz.(10)
IO.puts fiz_buz.(11)
IO.puts fiz_buz.(12)
IO.puts fiz_buz.(13)
IO.puts fiz_buz.(14)
IO.puts fiz_buz.(15)
IO.puts fiz_buz.(16)
