defmodule M do
  defmacro defreq({function_name, _, [function_body]} = head) do
    # IO.inspect function_body
    # IO.puts "begin to quote"
    IO.inspect function_body

    #case1
    # quote do
    #   unquote(IO.inspect function_body)

    #   def unquote(function_name)(_name) do
    #     unquote(function_body).(%{status: "hello"})
    #   end
    # end

    #case 2
    # IO.inspect(function_body)
    body = Macro.escape(function_body)
    # IO.inspect(body)
    quote bind_quoted: [function_name: function_name, function_body: body] do

      IO.inspect function_body
      def unquote(function_name)(_name) do
        unquote(function_body).(%{status: "hello"})
      end
    end
  end
end
