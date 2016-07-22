
defmodule Issues.Cli do

  import Issues.TableFormatter, only: [print_table_for_columns: 2]
  require Logger

  @default_count 4

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do

    parse = OptionParser.parse(argv, switches: [help: :boolean], alias: [h: :help])

    case parse do
      {[help: true], _, _} ->
        :help
      {[], [user, project, count], _} ->
        {user, project, String.to_integer(count)}
      {[], [user, project], _} ->
        {user, project, @default_count}
      _ ->
        :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)

    IO.puts "Error fetching from github: #{message}"
    System.halt(2)
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort(list_of_issues, fn issue1, issue2 -> issue1["create_at"] <= issue2["create_at"] end)
  end

end
