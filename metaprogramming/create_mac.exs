defmodule Mac do
  defmacro mydef(name) do
    quote bind_quoted: [name: name] do
      def unquote(name)() do
        IO.puts "hello #{unquote(name)}"
      end
    end
  end
end
