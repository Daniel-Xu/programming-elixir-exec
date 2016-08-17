defmodule Spider do
  use Hound.Helpers

  @root "/Users/danielxu/Desktop/embercast/"
  @website_root "https://www.emberscreencasts.com"

  def run do
    login()
    get_urls()
    |> Enum.reverse()
    |> Enum.map(&get_video(&1, get_title(&1)<>".mp4"))
  end

  def login do
    IO.puts "login start..."

    Hound.start_session()
    navigate_to "https://www.emberscreencasts.com/users/sign_in"

    find_element(:id, "user_email")
    |> fill_field("******")

    find_element(:id, "user_password")
    |> fill_field("********")

    find_element(:name, "commit")
    |> submit_element()
  end

  def download(src, output_filename) do
    IO.puts "Downloading #{src} -> #{output_filename}"
    body = HTTPoison.get!(src).body
    File.write!(output_filename, body)
    IO.puts "Done Downloading #{src} -> #{output_filename}"
  end

  def get_urls() do
    navigate_to "https://www.emberscreencasts.com/library"
    find_all_elements(:class, "archive-title")
    |> Enum.map(&find_within_element(&1, :tag, "a"))
    |> Enum.map(&attribute_value(&1, "href"))
  end

  def get_video(url, output_filename) do
    navigate_to url
    page_source()
    src = find_element(:tag, "source")
          |> attribute_value("src")
    spawn(Spider, :download, [src, @root <> output_filename])
  end

  def get_title(url) do
    url
    |> String.split("/")
    |> List.last()
  end
end
