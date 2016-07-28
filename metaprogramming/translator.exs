defmodule Translator do

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :locales, accumulate: true)
      import unquote(__MODULE__), only: [locale: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :locales))
    # should also work like this
    # compile(@locals)

  end

  defmacro locale(name, mappings) do
    quote bind_quoted: [name: name, mappings: mappings] do
      @locales {name, mappings}
    end
  end

  def compile(translations) do
    # TBD: Return AST for all translation function definitions
    translations_ast = for {locale, mappings} <- translations do
      deftranslations(locale, "", mappings)
    end

    quote do
      def t(locale, path, bindings \\ [])
      unquote(translations_ast)
      def t(_locale, _path, _bindings), do: {:error, :no_translation}
    end
  end

  defp deftranslations(locale, current_path, mappings) do
    for {key, value} <- mappings do
      path = append_path(current_path, key)
      if Keyword.keyword?(value) do
        deftranslations(locale, path, value)
      else
        quote do
          def t(unquote(locale), unquote(path), bindings) do
            unquote(interpolate(value))
          end
        end
      end
    end
  end

  defp append_path("", next), do: to_string(next)
  defp append_path(current_path, next), do: "#{current_path}.#{next}"

  defp interpolate(value) do
    ~r/(?<head>)%{[^}]+}(?<tail>)/
    |> Regex.split(value, on: [:head, :tail])
    |> Enum.reduce("", fn
      <<"%{" <> rest>>, acc ->
        key = String.to_atom(String.rstrip(rest, ?}))
        quote do
          unquote(acc) <> to_string(Dict.fetch!(bindings, unquote(key)))
        end
      segment, acc -> quote do: (unquote(acc) <> unquote(segment))
    end)
  end
end

