defmodule Repo do
  use Timex
  @access_token "**********"
  @block_list ~w(
    netflix-move-backend
    nimbus
    ember-cart
    apple-knox-backend
    shyft-rwe
    homu
    livin-api
    onboarding
    shyft-fts
    proposal-generator
    beemo
    how-we-doin-frontend
    how-we-don-backend)
  @orgs "DockYard"
  @home_prefix "/Users/danielxu/Desktop/"
  @repo_prefix "/Users/danielxu/Desktop/repos/"
  @branch_name "add-github-templates"
  @commit_msg "add-templates"

  Application.ensure_all_started :timex

  def run do
    create_client()
    |> repo_list()
    |> Enum.each(fn repo ->
      spawn(Repo, :pull_request, [repo])
    end)
  end

  def pull_request(repo) do
    push_commit(repo, @branch_name, @commit_msg)
    create_client
    |> make_pr(repo)

    IO.inspect repo["name"]
  end

  defp create_client do
    Tentacat.Client.new(%{access_token: @access_token})
  end

  defp repo_list(client) do
    Tentacat.Repositories.list_orgs(@orgs, client)
    # Tentacat.Repositories.list_mine(client, affiliation: "owner")
    |> Enum.filter(fn repo ->
      {:ok, updated_time} = Timex.parse(repo["updated_at"], "{ISO:Extended}")
      needed? = !Timex.before?(updated_time, Timex.to_date({2015, 10, 1}))
      needed? && !Enum.member?(@block_list, repo["name"])
    end)
    # |> Enum.take(2)
  end

  defp add_templates(repo_name) do
    # copy code of conduct to root
    code_of_conduct = "CODE_OF_CONDUCT.md"
    File.cp_r!(@home_prefix<>"root_github/#{code_of_conduct}", @repo_prefix<>repo_name<>"/#{code_of_conduct}")

    # copy and change contribution content to root
    contribution = "CONTRIBUTING.md"
    contribution_dest = @repo_prefix<>repo_name<>"/#{contribution}"
    File.cp_r!(@home_prefix<>"root_github/#{contribution}", contribution_dest)
    new_content =
      contribution_dest
      |> File.read!()
      |> String.replace("ember-service-worker", repo_name, global: true)
    File.write!(contribution_dest, new_content)

    # copy issue to .github
    # copy pull request to .github
    File.cp_r!(@home_prefix<>"hidden_github", @repo_prefix<>repo_name<>"/.github")
  end

  defp push_commit(repo, branch_name, commit_name) do
    {:ok, local_repo} = Git.clone [repo["ssh_url"], @repo_prefix <> repo["name"]]
    Git.checkout(local_repo, ~w(-b #{branch_name}))

    add_templates(repo["name"])

    Git.add(local_repo, ".")
    Git.commit(local_repo, ~w(-m #{commit_name}))
    Git.push(local_repo, ~w(--set-upstream origin #{branch_name}))
  end

  defp make_pr(client, repo) do
    body = %{
      "title" => @commit_msg,
      "head"  => @branch_name,
      "base"  => "master"
    }
    Tentacat.Pulls.create(repo["owner"]["login"], repo["name"], body, client)
  end
end
