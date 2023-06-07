defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  @type mappings :: [{{String.t(), atom, integer}, {String.t(), atom, integer}}]

  def trace(event, env) do
    Viz.Server.log_event(event, env)
  end

  @typep pseudo_mfa :: {String.t(), atom(), integer()}
  @spec export(module(), String.t(), [pseudo_mfa()] | nil, [pseudo_mfa()] | nil) ::
          {:ok, String.t()}
  def export(exporter, filename, sources, sinks) do
    filename = filename || exporter.default_filename()

    Server.get_mappings()
    |> then(&if(sources, do: source(sources, &1), else: &1))
    |> then(&if(sinks, do: sink(sinks, &1), else: &1))
    |> exporter.export()
    |> then(&File.write(filename, &1))

    {:ok, filename}
  end

  # Performs what is roughly program slicing, where the target variable in the
  # output of the function or functions provided in the first argument.
  #
  # Currently uses BFS algorithm to prevent having to uniquify the return value.
  defp source([], _mappings), do: []

  defp source(funs, mappings) do
    {calls, other_mappings} = Enum.split_with(mappings, fn {a, _b} -> a in funs end)

    callees = Enum.map(calls, &elem(&1, 1))

    calls ++ source(callees, other_mappings)
  end

  defp sink([], _mappings), do: []

  defp sink(funs, mappings) do
    {calls, other_mappings} = Enum.split_with(mappings, fn {_a, b} -> b in funs end)

    callers = Enum.map(calls, &elem(&1, 0))

    calls ++ sink(callers, other_mappings)
  end
end
