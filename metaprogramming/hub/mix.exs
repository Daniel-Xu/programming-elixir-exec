defmodule Hub.Mixfile do
  use Mix.Project

  def project do
    [app: :hub,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :timex, :tentacat]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:poison, "~> 1.3.0"},
     {:httpoison, "~> 0.9.0"},
     {:tentacat, "~> 0.5"},
     {:timex, "~> 3.0"},
     {:git_cli, "~> 0.2"},
     {:apex, "~>0.5.2"}]
  end
end
