defmodule ExTablerIcons do
  @latest_version "1.60.0"

  @tabler_icons_repo "https://github.com/tabler/tabler-icons.git"
  @tabler_icons_repo_remote "origin"
  @tabler_icons_repo_main_branch "master"

  @moduledoc """
  Runner for [tabler-icons](https://github.com/tabler/tabler-icons).

  ## Profiles

  You can define multiple ex_tabler_icons profiles. By default, there is a
  profile called `:default` for which you can configure its args and current
  directory:

      config :ex_tabler_icons,
          version: "#{@latest_version}",
          tabler_icons_repo: "https://github.com/tabler/tabler-icons.git",
          default: [
            cd: Path.expand("../assets", __DIR__),
            config_file: "tabler_icons.json",
            font_output: "../priv/static/fonts/"
            css_output: "css/"
          ],
          umbrella_default: [
            cd: Path.expand("../apps/my_app/assets", __DIR__),
            config_file: "tabler_icons.json",
            font_output: "../priv/static/fonts/",
            css_output: "css/"
          ]

  You may also set `version` to `:main` if you wish to track the main branch on the
  tabler icons repository.
  """

  use Application
  require Logger

  @doc false
  def start(_, _) do
    unless Application.get_env(:ex_tabler_icons, :version) do
      Logger.warn("""
      ex_tabler_icons version is not configured. Please set it in your config files:

          config :ex_tabler_icons, :version, "#{latest_version()}"
      """)
    end

    verify_tabler_icons_repo()
    verify_version()

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Returns the configured ex_tabler_icons version.
  """
  def configured_tabler_icons_repo do
    Application.get_env(:ex_tabler_icons, :tabler_icons_repo, @tabler_icons_repo)
  end

  def installed_tabler_icons_repo do
    path = tabler_icons_path()

    if File.exists?(path) do
      {:ok, run_simple_output_git_command(["remote", "get-url", @tabler_icons_repo_remote])}
    else
      :error
    end
  end

  defp verify_tabler_icons_repo() do
    configured_repo = configured_tabler_icons_repo()

    case installed_tabler_icons_repo() do
      {:ok, ^configured_repo} ->
        :ok

      {:ok, tabler_icons_repo} ->
        Logger.warn("""
        Outdated tabler icons repo. Expected #{configured_repo}, got #{tabler_icons_repo}. \
        Please run `mix ex_tabler_icons.install` or update the `tabler_icons_repo` value in your config files.\
        """)

      :error ->
        :ok
    end
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version, do: @latest_version

  @doc """
  Returns the configured ex_tabler_icons version.
  """
  def configured_version do
    Application.get_env(:ex_tabler_icons, :version, latest_version())
  end

  @doc """
  Returns the version of the local tabler icons repository.

  Returns `{:ok, version_string}` on success or `:error` when the repository
  is not available.
  """
  def installed_version do
    path = tabler_icons_path()

    with true <- File.exists?(path),
         {:ok, body} <- File.read(Path.join(path, "package.json")),
         {:ok, json} <- Jason.decode(body) do
      {:ok, Map.get(json, "version")}
    else
      _ -> :error
    end
  end

  defp verify_version() do
    case configured_version() do
      :main ->
        verify_main()

      version_tag ->
        verify_version_by_tag(version_tag)
    end
  end

  defp verify_main() do
    path = tabler_icons_path()

    if File.exists?(path) do
      System.cmd("git", ["fetch", @tabler_icons_repo_remote, @tabler_icons_repo_main_branch],
        cd: path,
        stderr_to_stdout: true
      )

      head_commit = run_simple_output_git_command(["rev-parse", "HEAD"])

      origin_main_commit =
        run_simple_output_git_command([
          "rev-parse",
          "#{@tabler_icons_repo_remote}/#{@tabler_icons_repo_main_branch}"
        ])

      case head_commit do
        ^origin_main_commit ->
          :ok

        _ ->
          Logger.warn("""
          Outdated main commit. Please run `mix ex_tabler_icons.install`.\
          """)

          :error
      end
    else
      :ok
    end
  end

  defp verify_version_by_tag(configured_version_tag) do
    case installed_version() do
      {:ok, ^configured_version_tag} ->
        :ok

      {:ok, version} ->
        Logger.warn("""
        Outdated ex_tabler_icons version. Expected #{configured_version_tag}, got #{version}. \
        Please run `mix ex_tabler_icons.install` or update the version in your config files.\
        """)

        :error

      :error ->
        :ok
    end
  end

  defp tabler_icons_path do
    Path.expand("../vendor/tabler-icons", __DIR__)
  end

  defp config_for!(profile) when is_atom(profile) do
    Application.get_env(:ex_tabler_icons, profile) ||
      raise ArgumentError, """
      unknown ex_tabler_icons profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :ex_tabler_icons,
            version: "#{@latest_version}",
            #{profile}: [
              cd: Path.expand("../assets", __DIR__),
              config_file: "tabler_icons.json",
              font_output: "../priv/static/fonts/"
              css_output: "css/"
            ]
      """
  end

  def execute(profile) do
    unless File.exists?(tabler_icons_path()) do
      install()
    end

    run(profile)
    copy_files(profile)

    0
  end

  defp run(profile) when is_atom(profile) do
    config = config_for!(profile)
    path = tabler_icons_path()

    current_directory = config[:cd] || File.cwd!()

    config_file_location = Path.join(path, "compile-options.json")
    # ensures we fall back on the tabler icons default config
    File.rm_rf!(config_file_location)

    if config[:config_file] do
      File.cp!(
        Path.join(current_directory, config[:config_file]),
        config_file_location
      )
    end

    System.cmd("npm", ["run", "build-iconfont"], cd: path)
  end

  def copy_files(profile) when is_atom(profile) do
    config = config_for!(profile)
    path = tabler_icons_path()
    current_directory = config[:cd] || File.cwd!()

    font_output = Path.join([current_directory, config[:font_output] || "fonts/"])
    File.cp_r!(Path.join([path, "iconfont", "fonts"]), font_output)

    css_output = Path.join([current_directory, config[:css_output] || "css/"])

    File.cp!(
      Path.join([path, "iconfont", "tabler-icons.css"]),
      Path.join([css_output, "tabler-icons.css"])
    )

    css_file = Path.join([css_output, "tabler-icons.css"])

    with true <- File.exists?(css_file),
         {:ok, body} <- File.read(css_file),
         replaced_body <- Regex.replace(~r/fonts\//, body, "/fonts/") do
      File.write(css_file, replaced_body)
    end

    :ok
  end

  def install do
    path = tabler_icons_path()
    tabler_icons_repo = configured_tabler_icons_repo()
    version = configured_version()

    if File.exists?(path) do
      System.cmd("git", ["remote", "set-url", @tabler_icons_repo_remote, tabler_icons_repo],
        cd: path
      )
    else
      vendor_dir = Path.expand("../vendor", __DIR__)
      File.mkdir_p!(vendor_dir)
      System.cmd("git", ["clone", tabler_icons_repo], cd: vendor_dir)
    end

    System.cmd("git", ["fetch", "--all", "--tags"], cd: path)

    checkout_commit =
      case version do
        :main ->
          "#{@tabler_icons_repo_remote}/#{@tabler_icons_repo_main_branch}"

        version_tag ->
          "tags/v#{version_tag}"
      end

    System.cmd("git", ["checkout", checkout_commit], cd: path, stderr_to_stdout: true)

    System.cmd("npm", ["install", "--legacy-peer-deps"], cd: path)
  end

  defp run_simple_output_git_command(command_parts) do
    path = tabler_icons_path()
    {output, 0} = System.cmd("git", command_parts, cd: path)
    String.trim(output)
  end
end
