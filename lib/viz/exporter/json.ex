defmodule Viz.Exporter.JSON do
  @moduledoc """
  Produces a JSON object containing two properties: an array of nodes and an array of edges.

  The `data` field of edge objects contain two keys `source` and `target` which
  represent the caller function can callee function, respectively.
  """

  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "out.json"

  @impl Viz.Exporter
  def export(mappings) do
    functions = Enum.flat_map(mappings, &Tuple.to_list/1)

    nodes = Enum.map(functions, &id/1)

    edges =
      mappings
      |> Enum.map(fn {source, target} ->
        "{\"source\": #{id(source)}, \"target\": #{id(target)}}"
      end)

    """
    {"nodes": [#{Enum.join(nodes, ",")}], "edges": [#{Enum.join(edges, ",")}]}
    """
  end

  defp id({mod, fun, arity}) do
    "{\"module\": #{inspect(String.split(mod, "."))}, \"function\": \"#{fun}/#{arity}\"}"
  end
end
