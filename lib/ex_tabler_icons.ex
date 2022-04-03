defmodule ExTablerIcons do
  @latest_version "1.50.0"

  @moduledoc """
  Runner for [tabler-icons](https://github.com/tabler/tabler-icons).

  ## Profiles

  You can define multiple ex_tabler_icons profiles. By default, there is a
  profile called `:default` for which you can configure its args and current
  directory:

      config :ex_tabler_icons,
          version: "#{@latest_version}",
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

    configured_version = configured_version()

    case installed_version() do
      {:ok, ^configured_version} ->
        :ok

      {:ok, version} ->
        Logger.warn("""
        Outdated ex_tabler_icons version. Expected #{configured_version}, got #{version}. \
        Please run `mix ex_tabler_icons.install` or update the version in your config files.\
        """)

      :error ->
        :ok
    end

    Supervisor.start_link([], strategy: :one_for_one)
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

  defp tabler_icons_path do
    Path.expand("../vendor/tabler-icons", __DIR__)
  end

  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
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

  def run(profile) when is_atom(profile) do
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
    version = configured_version()

    unless File.exists?(path) do
      vendor_dir = Path.expand("../vendor", __DIR__)
      File.mkdir_p!(vendor_dir)
      System.cmd("git", ["clone", "https://github.com/tabler/tabler-icons.git"], cd: vendor_dir)
    end

    System.cmd("git", ["fetch", "--all", "--tags"], cd: path)
    System.cmd("git", ["checkout", "tags/v#{version}"], cd: path)

    System.cmd("npm", ["install", "--legacy-peer-deps"], cd: path)
  end
end
