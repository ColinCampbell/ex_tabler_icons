defmodule Mix.Tasks.ExTablerIcons do
  @moduledoc """
  Invokes tabler icons with the given args.

  Usage:

      $ mix ex_tabler_icons TASK_OPTIONS PROFILE

  Example:

      $ mix ex_tabler_icons default

  ## Options

    * `--runtime-config` - load the runtime configuration
      before executing command

  Note flags to control this Mix task must be given before the
  profile:

      $ mix ex_tabler_icons --runtime-config default
  """

  @shortdoc "Invokes tabler_icons with the profile and args"

  use Mix.Task

  @impl true
  def run(args) do
    switches = [runtime_config: :boolean]
    {opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if opts[:runtime_config] do
      Mix.Task.run("app.config")
    else
      Application.ensure_all_started(:tabler_icons)
    end

    Mix.Task.reenable("ex_tabler_icons")
    run_tabler_icons(remaining_args)
  end

  defp run_tabler_icons([profile]) do
    case ExTablerIcons.execute(String.to_atom(profile)) do
      0 ->
        :ok

      status ->
        Mix.raise("`mix ex_tabler_icons` exited with #{status}")
        :error
    end
  end
end
