defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  @typep pseudo_mfa :: {String.t(), atom(), integer()}
  @type call :: {caller :: pseudo_mfa(), callee :: pseudo_mfa()}
  @type analyzer :: module()
  @type exporter :: module()

  @spec run(
          [analyzer()],
          exporter(),
          String.t() | nil,
          [pseudo_mfa()] | nil,
          [pseudo_mfa()] | nil
        ) :: {:ok, String.t()}
  def run(analyzers, exporter, filename, sources, sinks) do
    analyzers
    |> analyze()
    |> slice(sources, sinks)
    |> export(exporter, filename)
  end

  @spec analyze([analyzer()]) :: [call()]
  def analyze(analyzers) do
    analyzers
    |> Enum.flat_map(& &1.analyze())
    |> Enum.uniq()
  end

  @spec slice([call()], [pseudo_mfa()] | nil, [pseudo_mfa()] | nil) :: [call()]
  def slice(calls, sources, sinks) do
    calls
    |> then(&if(sources, do: source(sources, &1), else: &1))
    |> then(&if(sinks, do: sink(sinks, &1), else: &1))
  end

  @spec export([call()], exporter(), String.t() | nil) :: {:ok, String.t()}
  def export(calls, exporter, filename) do
    filename = filename || exporter.default_filename()

    calls
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
