defmodule CliTest do
  use ExUnit.Case
  doctest Issues

  import Issues.Cli, only: [ parse_args: 1 ]

  test "-h and --h option" do
    assert parse_args(["-h", "_"]) == :help
    assert parse_args(["--help", "_"]) == :help
  end

  test "three values returned if three given" do
    assert parse_args(["user", "project", "39"]) == {"user", "project", 39}
  end

  test "default value returned if two given" do
    assert parse_args(["user", "project"]) == {"user", "project", 4}
  end
end
