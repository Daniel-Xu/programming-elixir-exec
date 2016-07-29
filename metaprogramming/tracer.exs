defmodule Tracer do
  defmacro deftraceable(head, body) do
    quote bind_quoted: [
      head: Macro.escape(head),
      body: Macro.escape(body)
    ] do

    IO.inspect Macro.to_string head
    IO.inspect Macro.to_string body
      {fun_name, args_ast} = Tracer.name_and_args(head)
      {arg_names, decorated_args} = Tracer.decorate_args(args_ast)

      head = Macro.postwalk(head,
        fn
          ({fun_ast, context, old_args}) when (
            fun_ast == fun_name and old_args == args_ast
          ) ->
            {fun_ast, context, decorated_args}
          (other) -> other
      end)

      def unquote(head) do
        file = __ENV__.file
        line = __ENV__.line
        module = __ENV__.module

        function_name = unquote(fun_name)
        passed_args = unquote(arg_names) |> Enum.map(&inspect/1) |> Enum.join(",")

        result = unquote(body[:do])

        loc = "#{file}(line #{line})"
        call = "#{module}.#{function_name}(#{passed_args}) = #{inspect result}"
        IO.puts "#{loc} #{call}"

        result
      end
    end
  end

  def name_and_args({:when, _, [short_head | _]}) do
    name_and_args(short_head)
  end

  def name_and_args(short_head) do
    Macro.decompose_call(short_head)
  end

  def decorate_args([]), do: {[],[]}
  def decorate_args(args_ast) do
    for {arg_ast, index} <- Enum.with_index(args_ast) do
      arg_name = Macro.var(:"arg#{index}", __MODULE__)

      full_arg = quote do
        unquote(arg_ast) = unquote(arg_name)
      end

      {arg_name, full_arg}
    end
    |> Enum.unzip
  end
end

