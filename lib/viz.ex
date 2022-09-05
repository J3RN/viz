defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  def trace(event, env) do
    :ok = Application.ensure_started(:viz)
    :ok = GenServer.call(Viz.Server, {event, env})
    :ok
  end
end
