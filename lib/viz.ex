defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  @type mappings :: [{{String.t(), atom, integer}, {String.t(), atom, integer}}]

  def trace(event, env) do
    Viz.Server.log_event(event, env)
  end

  def export(exporter, opts \\ []) do
    with {:ok, opts} <-
           Keyword.validate(opts, filename: exporter.default_filename(), sinks: nil, sources: nil) do
      filename = Keyword.get(opts, :filename)
      sources = Keyword.get(opts, :sources)
      sinks = Keyword.get(opts, :sinks)

      Server.get_mappings()
      |> then(&if(sources, do: source(sources, &1), else: &1))
      |> then(&if(sinks, do: sink(sinks, &1), else: &1))
      |> exporter.export()
      |> then(&File.write(filename, &1))

      {:ok, filename}
    else
      {:error, opt_names} -> {:error, :unknown_options, opt_names}
    end
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
