defmodule Translator do

  defmacro __use__(opts) do
    Module.register_attribute(__MODULE__, :locals, accumulate: true)
    import unquote(__MODULE__), only: [locale: 2]
    @before_compile unquote(__MODULE__)
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :locales))
  end

  defmacro locale(name, mappings) do
    quote bind_quoted: [name: name, mappings: mappings] do
      @locales {name, mappings}
    end
  end

  def compile(translations) do
    # TBD: Return AST for all translation function definitions
  end
end
