defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  def trace(event, env) do
    Server.log_event(event, env)
  end

  def export(exporter, opts \\ []) do
    [filename: filename] = Keyword.validate!(opts, filename: exporter.default_filename())

    Server.get_state()
    |> exporter.export()
    |> tap(&File.write(filename, &1))

    filename
  end
end
