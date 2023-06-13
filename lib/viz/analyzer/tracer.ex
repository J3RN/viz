defmodule Viz.Analyzer.Tracer do
  @behaviour Viz.Analyzer

  alias __MODULE__.Server

  def analyze() do
    Server.start_link([])
    Mix.Task.run("compile", ["--force", "--tracer", "Viz.Analyzer.Tracer"])
    Server.get_calls()
  end

  def trace(event, env) do
    Server.log_event(event, env)
  end
end
