defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  @typep pseudo_mfa :: {String.t(), atom(), integer()}
  @type calls :: [{callers :: pseudo_mfa(), callee :: pseudo_mfa()}]

  def trace(event, env) do
    Viz.Server.log_event(event, env)
  end

  @spec export(module(), String.t(), [pseudo_mfa()] | nil, [pseudo_mfa()] | nil) ::
          {:ok, String.t()}
  def export(exporter, filename, sources, sinks) do
    filename = filename || exporter.default_filename()

    Server.get_calls()
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
  defp source([], _calls), do: []

  defp source(funs, calls) do
    {calls, other_calls} = Enum.split_with(calls, fn {a, _b} -> a in funs end)

    callees = Enum.map(calls, &elem(&1, 1))

    calls ++ source(callees, other_calls)
  end

  defp sink([], _calls), do: []

  defp sink(funs, calls) do
    {calls, other_calls} = Enum.split_with(calls, fn {_a, b} -> b in funs end)

    callers = Enum.map(calls, &elem(&1, 0))

    calls ++ sink(callers, other_calls)
  end
end
