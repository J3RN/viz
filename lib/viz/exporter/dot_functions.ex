defmodule Viz.Exporter.DotFunctions do
  @moduledoc """
  Creates a GraphViz data file which contains a call graph of only functions,
  with no data on modules outside of their names being part of the functions'
  names.
  """

  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "functions.dot"

  @impl Viz.Exporter
  def export(mappings) do
    calls =
      mappings
      |> Enum.map(fn {source, target} ->
        ~s|"#{hash(source)}" -> "#{hash(target)}";|
      end)
      |> Enum.join("\n")

    """
    digraph {
    graph [ranksep = 4.0]
    #{calls}
    }
    """
  end
end
