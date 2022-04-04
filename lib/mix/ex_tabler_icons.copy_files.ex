defmodule Mix.Tasks.ExTablerIcons.CopyFiles do
  @moduledoc """
  Moves the built tabler-icons files into other directories.

  ```bash
  $ mix ex_tabler_icons.copy_files PROFILE
  ```
  """

  @shortdoc "Copies built tabler-icons files"
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

    Mix.Task.reenable("ex_tabler_icons.copy_files")
    copy_files(remaining_args)
  end

  defp copy_files([profile]) do
    ExTablerIcons.copy_files(String.to_atom(profile))
  end
end
