defmodule Mix.Tasks.ExTablerIcons.Install do
  @moduledoc """
  Installs tabler-icons.

  ```bash
  $ mix ex_tabler_icons.install
  ```

  By default, it installs #{ExTablerIcons.latest_version()} but you
  can configure it in your config files, such as:

      config :ex_tabler_icons, :version, "#{ExTablerIcons.latest_version()}"

  ## Options

      * `--runtime-config` - load the runtime configuration
        before executing command
  """

  @shortdoc "Installs tabler-icons"
  use Mix.Task

  @impl true
  def run(args) do
    valid_options = [runtime_config: :boolean]

    case OptionParser.parse_head!(args, strict: valid_options) do
      {opts, []} ->
        if opts[:runtime_config], do: Mix.Task.run("app.config")
        ExTablerIcons.install()

      {_, _} ->
        Mix.raise("""
        Invalid arguments to ex_tabler_icons.install, expected one of:

            mix ex_tabler_icons.install
            mix ex_tabler_icons.install --runtime-config
        """)
    end
  end
end
