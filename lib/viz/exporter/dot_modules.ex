defmodule Viz.Exporter.DotModules do
  use Viz.Exporter

  @impl Viz.Exporter
  def export(mappings) do
    body =
      Enum.map(mappings, fn {{sourcem, sourcef, sourcea}, {targetm, _, _}} ->
        ~s|"#{sourcem}" -> "#{targetm}" [label = "#{sourcef}/#{sourcea}"]|
      end)
      |> Enum.join("\n")

    """
    digraph {
    graph [ranksep = 4.0]
    #{body}
    }
    """
  end
end
