defmodule Viz.Exporter.Cytoscape do
  use Viz.Exporter

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
