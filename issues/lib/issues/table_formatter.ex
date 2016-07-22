defmodule Issues.TableFormatter do
  import Enum, only: [each: 2, map: 2, map_join: 3, max: 1]

  def print_table_for_columns(rows, headers) do
    with columns_data = split_into_columns(rows, headers),
         widths = width_of(columns_data),
         format = format_for(widths)
    do
      put_in_one_row(headers, format)
      IO.puts(separator(widths))
      put_in_colums(columns_data, format)
    end
  end

  def printable(str) when is_binary(str), do: str
  def printable(str), do: to_string(str)

  def split_into_columns(rows, headers) do
    for header <- headers do
      for row <- rows do
        printable(row[header])
      end
    end
  end

  def width_of(columns) do
    for column <- columns do
      column
      |> map(&String.length/1)
      |> max
    end
  end

  def format_for(widths) do
    map_join(widths, " | ", fn width -> "~-#{width}s" end) <> "~n"
  end

  def separator(widths) do
    map_join(widths, "-+-", fn width -> List.duplicate("-", width) end)
  end

  def put_in_colums(data_by_columns, format) do
    data_by_columns
    |> List.zip
    |> map(&Tuple.to_list/1)
    |> each(&put_in_one_row(&1, format))
  end

  def put_in_one_row(fields, format) do
    :io.format(format, fields)
  end
end
