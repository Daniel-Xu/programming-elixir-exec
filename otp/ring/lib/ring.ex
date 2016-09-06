defmodule Ring do

  def gen(n) do
    1..n
    |> Enum.map(fn _ ->
      spawn(fn -> loop end)
    end)
  end

  def loop do
    receive do
      {:link, link_to} when is_pid(link_to) ->
        Process.link(link_to)
        loop
      :trap_exit ->
        Process.flag(:trap_exit, true)
        loop
      :crash ->
        1/0
      {:EXIT, pid, reason} ->
        IO.puts "#{inspect self} receives {:EXIT, #{inspect pid}, #{reason}}"
        loop
    end
  end

  def link_processes(procs) do
    link_processes(procs, [])
  end
  def link_processes([proc1, proc2|rest], linked_procs) do
    send(proc1, {:link, proc2})
    link_processes([proc2|rest], [proc1|linked_procs])
  end
  def link_processes([last_proc|[]], linked_procs) do
    first_proc = List.last(linked_procs)
    send(last_proc, {:link, first_proc})
  end

end
