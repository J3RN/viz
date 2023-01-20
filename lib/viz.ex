defmodule Viz do
  @moduledoc """
  Compilation tracer that generates call graphs.
  """

  alias __MODULE__.Server

  @type mappings :: [{{String.t(), atom, integer}, {String.t(), atom, integer}}]

  def trace(event, env) do
    Server.log_event(event, env)
  end

  def export(exporter, opts \\ []) do
    with {:ok, opts} <- Keyword.validate(opts, filename: exporter.default_filename(), slices: nil) do
      filename = Keyword.get(opts, :filename)
      slices = Keyword.get(opts, :slices)

      Server.get_mappings()
      |> then(&if(slices, do: slice(slices, &1), else: &1))
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
  defp slice([], _mappings), do: []

  defp slice(funs, mappings) do
    {calls, other_mappings} = Enum.split_with(mappings, fn {a, _b} -> a in funs end)

    callees = Enum.map(calls, &elem(&1, 1))

    calls ++ slice(callees, other_mappings)
  end
end
