defmodule ControlFlow do
  defmacro myif(expr, do: if_block) do
    if(expr, do: if_block, else: nil)
  end

  defmacro myif(expr, do: if_block, else: else_block) do
    quote do
      case unquote(expr) do
        value when value in [false, nil] ->
          unquote(else_block)
        _ ->
          unquote(if_block)
      end
    end
  end

  defmacro while(expression, do: block) do
    quote do
      try do
        for _ <- Stream.cycle([:ok]) do
          if unquote(expression) do
            unquote(block)
          else
            Loop.break
          end
        end
      catch
        :break-> :ok
      end

    end
  end

  def break, do: throw :break
end
