defmodule Viz.Exporter.Cytoscape do
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
    functions = extract_functions(mappings)
    modules = extract_modules(functions)

    nodes =
      Enum.map(modules, fn {mod, parent} ->
        "{\"group\": \"nodes\", \"data\": {\"id\": \"#{mod}\", \"label\": \"#{mod}\", \"type\": \"module\"#{if parent, do: ", \"parent\": \"#{parent}\"", else: ""}}}"
      end)
      |> Enum.concat(
        Enum.map(functions, fn mfa = {mod, _f, _a} ->
          "{\"group\": \"nodes\", \"data\": {\"id\": \"#{hash(mfa)}\", \"parent\": \"#{mod}\", \"label\": \"#{hash(mfa)}\", \"type\": \"function\"}}"
        end)
      )

    edges =
      mappings
      |> Enum.map(fn {source, target} ->
        "{\"group\": \"edges\", \"data\": {\"id\": \"#{hash(source)}->#{hash(target)}\", \"source\": \"#{hash(source)}\", \"target\": \"#{hash(target)}\"}}"
      end)

    """
    [
    #{Enum.join(nodes ++ edges, ",\n")}
    ]
    """
  end

  # Convert [{a, b}, {c, d}] to [a, b, c, d]
  defp extract_functions(mappings) do
    mappings
    |> Enum.flat_map(&Tuple.to_list/1)
    |> MapSet.new()
  end

  defp extract_modules(functions) do
    functions
    |> Enum.flat_map(fn {m, _f, _a} ->
      # Turn "Foo.Bar.Baz" into ["Foo", "Foo.Bar", "Foo.Bar.Baz"]
      m
      |> String.split(".")
      |> Enum.scan(nil, fn
        mod, nil -> {mod, nil}
        mod, {parent, _grandparent} -> {"#{parent}.#{mod}", parent}
      end)
    end)
    |> MapSet.new()
  end
end
