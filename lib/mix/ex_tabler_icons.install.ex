defmodule Mix.Tasks.ExTablerIcons.Install do
  @moduledoc """
  Installs tabler-icons.

  ```bash
  $ mix ex_tabler_icons.install
  $ mix ex_tabler_icons.install --if-missing
  ```

  By default, it installs #{ExTablerIcons.latest_version()} but you
  can configure it in your config files, such as:

      config :ex_tabler_icons, :version, "#{ExTablerIcons.latest_version()}"

  ## Options

      * `--runtime-config` - load the runtime configuration
        before executing command

      * `--if-missing` - install only if the given version
        does not exist
  """

  @shortdoc "Installs tabler-icons"
  use Mix.Task

  @impl true
  def run(args) do
    valid_options = [runtime_config: :boolean, if_missing: :boolean]

    case OptionParser.parse_head!(args, strict: valid_options) do
      {opts, []} ->
        if opts[:runtime_config], do: Mix.Task.run("app.config")

        if opts[:if_missing] && latest_version?() do
          :ok
        else
          ExTablerIcons.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to ex_tabler_icons.install, expected one of:

            mix ex_tabler_icons.install
            mix ex_tabler_icons.install --runtime-config
            mix ex_tabler_icons.install --if-missing
        """)
    end
  end

  defp latest_version?() do
    version = ExTablerIcons.configured_version()
    match?({:ok, ^version}, ExTablerIcons.installed_version())
  end
end
