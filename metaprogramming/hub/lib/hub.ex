defmodule Repo do

  HTTPoison.start
  res = HTTPoison.get "https://api.github.com/users/daniel-xu/repos?access_token=4d595e394ccaac7705abbca07760774180060b2c"
  {:ok, %{body: body}} = res

  Poison.Parser.parse!(body)
  |> Enum.each(fn repo ->
    def unquote(String.to_atom(repo["name"]))() do
      unquote(Macro.escape(repo))
    end
  end)


  def go(repo) do
    url = apply(__MODULE__, repo, [])["html_url"]
    IO.puts "Launching browser to #{url}"
    System.cmd("open", [url])
  end
end
