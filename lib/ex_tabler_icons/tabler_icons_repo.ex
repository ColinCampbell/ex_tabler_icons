defmodule ExTablerIcons.TablerIconsRepo do
  @url "https://github.com/tabler/tabler-icons.git"
  @remote "origin"
  @main_branch "master"

  require Logger

  def install(path) do
    tabler_icons_repo = configured_tabler_icons_repo()
    version = configured_version()

    if File.exists?(path) do
      System.cmd("git", ["remote", "set-url", @remote, tabler_icons_repo], cd: path)
    else
      vendor_dir = Path.expand("../vendor", __DIR__)
      File.mkdir_p!(vendor_dir)
      System.cmd("git", ["clone", tabler_icons_repo], cd: vendor_dir)
    end

    checkout_commit =
      case version do
        :main ->
          fetch(path, @main_branch)
          "#{@remote}/#{@main_branch}"

        version_tag ->
          fetch(path, "+refs/#{tag(version_tag)}:refs/#{tag(version_tag)}")
          "tags/v#{version_tag}"
      end

    System.cmd("git", ["checkout", checkout_commit], cd: path, stderr_to_stdout: true)

    System.cmd("npm", ["install", "--legacy-peer-deps"], cd: path)

    :ok
  end

  def restore_files(path, files) do
    System.cmd("git", ["restore"] ++ files, cd: path)
  end

  defp configured_tabler_icons_repo do
    Application.get_env(:ex_tabler_icons, :tabler_icons_repo, @url)
  end

  def verify(path) do
    case {verify_repo(path), verify_version(path)} do
      {:ok, :ok} ->
        :ok

      {:ok, error} ->
        error

      {error, _} ->
        error
    end
  end

  defp verify_repo(path) do
    configured_repo = configured_tabler_icons_repo()

    case installed_tabler_icons_repo(path) do
      {:ok, ^configured_repo} ->
        :ok

      {:ok, tabler_icons_repo} ->
        {:outdated_repo_error, configured_repo, tabler_icons_repo}

      :error ->
        Logger.info("""
          Repostiory not found, installing...
        """)

        install(path)
    end
  end

  defp installed_tabler_icons_repo(path) do
    if File.exists?(path) do
      {:ok, run_simple_output_git_command(path, ["remote", "get-url", @remote])}
    else
      :error
    end
  end

  defp verify_version(path) do
    case configured_version() do
      :main ->
        case verify_main(path) do
          :ok ->
            :ok

          error ->
            error
        end

      version_tag ->
        case {verify_version_by_tag(path, version_tag),
              verify_version_by_commit(path, version_tag)} do
          {:ok, :ok} ->
            :ok

          {error, :ok} ->
            error

          {:ok, error} ->
            error

          {version_error, _commit_error} ->
            version_error
        end
    end
  end

  defp verify_main(path) do
    case verify_on_commit(
           path,
           "#{@remote}/#{@main_branch}",
           @main_branch
         ) do
      true ->
        :ok

      false ->
        :outdated_main_error
    end
  end

  defp verify_version_by_tag(path, configured_version_tag) do
    case installed_version(path) do
      {:ok, ^configured_version_tag} ->
        :ok

      {:ok, version} ->
        {:mismatched_version_error, configured_version_tag, version}

      :error ->
        :ok
    end
  end

  defp verify_version_by_commit(path, configured_version_tag) do
    tag_reference = tag(configured_version_tag)

    case verify_on_commit(
           path,
           tag_reference,
           "+refs/#{tag_reference}:refs/#{tag_reference}"
         ) do
      true ->
        :ok

      false ->
        {:incorrect_commit_error, configured_version_tag}
    end
  end

  defp configured_version do
    Application.get_env(:ex_tabler_icons, :version, ExTablerIcons.latest_version())
  end

  defp installed_version(path) do
    with true <- File.exists?(path),
         {:ok, body} <- File.read(Path.join(path, "package.json")),
         {:ok, json} <- Jason.decode(body) do
      {:ok, Map.get(json, "version")}
    else
      _ -> :error
    end
  end

  defp verify_on_commit(path, reference, remote_reference) do
    fetch(path, remote_reference)

    current_commit = commit_hash(path, "HEAD")
    referenced_commit = commit_hash(path, reference)

    current_commit == referenced_commit
  end

  defp commit_hash(path, reference) do
    run_simple_output_git_command(path, [
      "rev-list",
      "-n",
      "1",
      reference
    ])
  end

  defp run_simple_output_git_command(path, command_parts) do
    {output, 0} = System.cmd("git", command_parts, cd: path)
    String.trim(output)
  end

  defp fetch(path, ref) do
    System.cmd("git", ["fetch", @remote, ref],
      cd: path,
      stderr_to_stdout: true
    )
  end

  defp tag(version) do
    "tags/v#{version}"
  end
end
