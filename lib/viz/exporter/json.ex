defmodule Viz.Exporter.JSON do
  @moduledoc """
  Produces a JSON file containing a list of nodes and edges.

  This format is designed to be compatible with Cytoscape.js.

  Each edge or node contains a key `group` with a value of either `'nodes'` or
  `'edges'` and a key `data`.

  Every nodes' `data` value has a key `id`, which is its name.

  Some nodes' `data` fields have a `parent` key, indicating that the node is a
  function belonging to the module whose name is referenced in the value.

  The `data` field of edge objects contain two keys `source` and `target` which
  represent the caller function can callee function, respectively.
  """

  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "out.json"

  @impl Viz.Exporter
  def export(mappings) do
    modules =
      Enum.flat_map(mappings, fn {{sourcem, _, _}, {targetm, _, _}} -> [sourcem, targetm] end)

    functions = Enum.flat_map(mappings, &Tuple.to_list/1)

    nodes =
      Enum.map(modules, fn mod ->
        "{group: 'nodes', data: {id: '#{mod}'}}"
      end)
      |> Enum.concat(
        Enum.map(functions, fn mfa = {mod, _f, _a} ->
          "{group: 'nodes', data: {id: '#{hash(mfa)}', parent: '#{mod}'}}"
        end)
      )

    edges =
      mappings
      |> Enum.map(fn {source, target} ->
        "{group: 'edges', data: {source: '#{hash(source)}', target: '#{hash(target)}'}}"
      end)

    """
    [
    #{Enum.join(nodes ++ edges, ",\n")}
    ]
    """
  end
end
