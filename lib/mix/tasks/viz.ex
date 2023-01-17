defmodule Mix.Tasks.Viz do
  @moduledoc "The mix task Viz"
  use Mix.Task

  @shortdoc "Creates a vizualization data file from the codebase"
  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [format: :string, filename: :string])

    {format, other_opts} = Keyword.pop(opts, :format, "CSV")

    format
    |> string_to_exporter_module()
    |> do_run(other_opts)
  end

  defp do_run(exporter, opts) do
    :ok = Application.ensure_started(:viz)
    Mix.Task.run("compile", ["--force", "--tracer", "Viz"])
    filename = Viz.export(exporter, opts)

    Mix.shell().info("Call graph written to #{filename}!")
  end

  # This is dark magic, but allows for third parties to provide exporters (I think)
  defp string_to_exporter_module(str) do
    exporter =
      str
      |> Macro.camelize()
      |> then(&("Elixir.Viz.Exporter." <> &1))
      |> String.to_atom()

    Code.ensure_loaded!(exporter)

    exporter
  end
end
