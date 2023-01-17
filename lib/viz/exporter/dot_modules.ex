defmodule Viz.Exporter.DotModules do
  @moduledoc """
  Exports a call-graph that show the relationships between different modules.
  Each edge from one module to another is labelled with the function name of the
  caller function.
  """

  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "modules.dot"

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
