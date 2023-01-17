defmodule Viz.Exporter.MyDot do
  use Viz.Exporter

  @impl Viz.Exporter
  def default_filename(), do: "mydot.dot"

  @impl Viz.Exporter
  def export(mappings) do
    [{"Instinct.Finance", :compute_invoice, 2}]
    |> children(mappings)
    |> Enum.filter(fn {{sourcemod, _, _}, {targetmod, _, _}} ->
      String.starts_with?(sourcemod, "Instinct.") && String.starts_with?(targetmod, "Instinct.")
    end)
    |> Viz.Exporter.Dot.export()
  end

  def children([], _mappings), do: []

  def children(funs, mappings) do
    {child_mappings, other_mappings} = Enum.split_with(mappings, fn {a, _b} -> a in funs end)

    children = Enum.map(child_mappings, &elem(&1, 1))

    child_mappings ++ children(children, other_mappings)
  end

  # Interesting, but not really what I want here.
  # def children(state, base_fun, history) do
  #   children = Enum.filter(state, fn {a, _b} -> a == base_fun && a not in history end)
  #   Map.new(children, fn {_base_fun, child} ->
  #     {child, children(state, child, [child | history])}
  #   end)
  # end
end
