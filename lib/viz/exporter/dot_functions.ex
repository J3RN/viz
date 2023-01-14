defmodule Viz.Exporter.DotFunctions do
  use Viz.Exporter

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
