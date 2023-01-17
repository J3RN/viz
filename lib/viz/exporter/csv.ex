defmodule Viz.Exporter.CSV do
  @moduledoc """
  Exports call graphs as a CSV where the sources (callers) are in the first
  column and their targets (callees) are in the second.
  """

  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "out.csv"

  @impl Viz.Exporter
  def export(mappings) do
    csv_header = "source,target\n"

    csv_body =
      mappings
      |> Enum.map(fn {s, t} -> ~s|"#{hash(s)}","#{hash(t)}"| end)
      |> Enum.join("\n")

    # Would an IO list work better here? 🤔
    csv_header <> csv_body
  end
end
