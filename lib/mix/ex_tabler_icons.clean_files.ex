defmodule Mix.Tasks.ExTablerIcons.CleanFiles do
  @moduledoc """
  Cleans the built tabler-icons files.

  ```bash
  $ mix ex_tabler_icons.clean_files
  ```
  """

  @shortdoc "Cleans built tabler-icons files"
  use Mix.Task

  @impl true
  def run(args) do
    switches = [runtime_config: :boolean]
    {opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if opts[:runtime_config] do
      Mix.Task.run("app.config")
    else
      Application.ensure_all_started(:ex_tabler_icons)
    end

    Mix.Task.reenable("ex_tabler_icons.clean_files")
    clean_files(remaining_args)
  end

  defp clean_files([]) do
    ExTablerIcons.clean_files()
  end
end
