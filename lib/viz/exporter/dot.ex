defmodule Viz.Exporter.Dot do
  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "out.dot"

  @impl Viz.Exporter
  def export(mappings) do
    modules =
      Enum.reduce(mappings, %{}, fn {{sourcem, sourcef, sourcea}, {targetm, targetf, targeta}},
                                    mods ->
        mods
        |> Map.update(sourcem, [{sourcef, sourcea}], &[{sourcef, sourcea} | &1])
        |> Map.update(targetm, [{targetf, targeta}], &[{targetf, targeta} | &1])
      end)
      |> Enum.map(fn {mod, functions} ->
        function_listing =
          Enum.map(functions, fn {f, a} ->
            ~s|"#{hash({mod, f, a})}" [label = "#{f}/#{a}"];|
          end)
          |> Enum.uniq()
          |> Enum.join("\n  ")

        """
        subgraph "cluster_#{mod}" {
          label = "#{mod}";
          style = "rounded,filled";
          color = lightgrey;
          node [style=filled, color=white];
          #{function_listing}
        }
        """
      end)

    calls =
      mappings
      |> Enum.map(fn {source, target} ->
        ~s|"#{hash(source)}" -> "#{hash(target)}";|
      end)
      |> Enum.join("\n")

    """
    digraph {
    graph [ranksep = 4.0]
    #{modules}
    #{calls}
    }
    """
  end
end
