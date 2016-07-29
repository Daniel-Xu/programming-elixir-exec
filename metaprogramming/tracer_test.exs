defmodule Test do
  import Tracer

  fsm = [
    running: {:pause, :paused},
    running: {:stop, :stopped},
    paused: {:resume, :running}
  ]

  for {state, {action, next_state}} <- fsm do
    deftraceable unquote(action)(unquote(state)), do: unquote(next_state)
  end
  deftraceable initial, do: :running
end
