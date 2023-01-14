defmodule Mix.Tasks.Viz do
  @moduledoc "The mix task Viz"
  use Mix.Task

  @shortdoc "Creates a vizualization data file from the codebase"
  @impl Mix.Task
  def run(_args) do
    :ok = Application.ensure_started(:viz)
    Mix.Task.run("compile", ["--force", "--tracer", "Viz"])
    Viz.export(Viz.Exporter.Dot)
  end
end
