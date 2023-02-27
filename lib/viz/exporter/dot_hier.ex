defmodule Viz.Exporter.DotHier do
  use Viz.Exporter

  defmodule Node do
    defstruct functions: [], children: %{}
  end

  @impl Viz.Exporter
  def default_filename(), do: "hier.dot"

  @impl Viz.Exporter
  def export(mappings) do
    modules =
      mappings
      |> Enum.flat_map(&Tuple.to_list/1)
      |> Enum.reduce(%Node{}, fn {qualified_mod, fun, arity} = mfa, root ->
        parts = String.split(qualified_mod, ".")

        put_in_hier(root, parts, {"#{fun}/#{arity}", mfa})
      end)
      |> format_hier()

    function_listing =
      mappings
      |> Enum.map(fn {source, target} ->
        ~s|"#{hash(source)}" -> "#{hash(target)}"|
      end)
      |> Enum.join("\n")

    """
    digraph {
    graph [ranksep=4.0]
    #{modules}
    #{function_listing}
    }
    """
  end

  defp format_hier(%Node{children: children, functions: functions}, parents \\ []) do
    function_listing =
      functions
      |> Enum.map(fn {simple, mfa} ->
        ~s|"#{hash(mfa)}" [label = "#{simple}"];|
      end)
      |> Enum.uniq()
      |> Enum.join("\n")

    children
    |> Enum.map(fn {name, child} ->
      qualified_path = parents ++ [name]
      qualified_name = Enum.join(qualified_path, ".")

      """
      subgraph "cluster_#{qualified_name}" {
        label = "#{name}";
        tooltip = "#{qualified_name}";
        style = "rounded,filled";
        color = blue;
        fillcolor = lightgrey;
        node [style=filled, color=white];

      #{format_hier(child, qualified_path) |> String.split("\n") |> Enum.map(&("  " <> &1)) |> Enum.join("\n")}
      }
      """
    end)
    |> Enum.join("\n")
    |> Kernel.<>(function_listing)
  end

  defp put_in_hier(%Node{functions: funs} = node, [], fun) do
    %Node{node | functions: [fun | funs]}
  end

  defp put_in_hier(%Node{children: children} = node, [first | rest], fun) do
    new_children =
      Map.update(
        children,
        first,
        put_in_hier(%Node{}, rest, fun),
        &put_in_hier(&1, rest, fun)
      )

    %Node{node | children: new_children}
  end
end
