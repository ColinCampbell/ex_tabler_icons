defmodule ExTablerIcons do
  @latest_version "1.60.0"

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
  alias ExTablerIcons.TablerIconsRepo

  @doc false
  def start(_, _) do
    unless Application.get_env(:ex_tabler_icons, :version) do
      Logger.warn("""
      ex_tabler_icons version is not configured. Please set it in your config file:

          config :ex_tabler_icons, :version, "#{latest_version()}"
      """)
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  def install() do
    TablerIconsRepo.install(tabler_icons_path())
  end

  def execute(profile) do
    case TablerIconsRepo.verify(tabler_icons_path()) do
      :ok ->
        run(profile)
        copy_files(profile)

        :ok

      {:outdated_repo_error, configured_repo, current_repo} ->
        Logger.warn("""
        Outdated tabler icons repo. Expected #{configured_repo}, got #{current_repo}. \
        Please run `mix ex_tabler_icons.install` or update the `tabler_icons_repo` value in your config file.\
        """)

        :error

      :outdated_main_error ->
        Logger.warn("""
        Outdated main commit. Please run `mix ex_tabler_icons.install`.\
        """)

        :error

      {:mismatched_version_error, configured_version_tag, version} ->
        Logger.warn("""
        Outdated ex_tabler_icons version. Expected #{configured_version_tag}, got #{version}. \
        Please run `mix ex_tabler_icons.install` or update the version in your config file.\
        """)

        :error

      {:incorrect_commit_error, configured_version_tag} ->
        Logger.warn("""
        Tabler icons is not on the commit for v#{configured_version_tag}. Please run `mix ex_tabler_icons.install`.\
        """)

        :error
    end
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version, do: @latest_version

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
end
