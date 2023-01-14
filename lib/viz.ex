defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  def trace(event, env) do
    Server.log_event(event, env)
  end

  def export(exporter) do
    Server.get_state()
    |> exporter.export()
    |> tap(&File.write("out.dot", &1))
  end
end
