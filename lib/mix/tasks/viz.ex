defmodule Mix.Tasks.Viz do
  @moduledoc """
  Visualize the call graph for your Elixir codebase.

  ## Usage

  ```
  $ mix viz
  ```

  This will create an out.csv file containing a call-graph of your application
  for analysis or importing into another tool.  It has two columns—`source` and
  `target`—and each row in the CSV represents a call from the `source` function
  to the `target` function.

  You may specify a different filename with the `--filename` flag, e.g.

  ```
  $ mix viz --filename myapp.csv
  ```

  You can also export the call-graph for only a "slice" of your program.  For
  instance, if you only want data on calls made in the course of the computation
  of `MyApp.foo/2`, you would write:

  ```
  $ mix viz --source MyApp.foo/2
  ```

  Multiple sources are supported and are "or"ed together.  That is, if you want
  data on calls made in the course of the computation of `MyApp.foo/2` and
  `MyApp.bar/1`, you would write:

  ```
  $ mix viz --source MyApp.foo/2 --source MyApp.bar/1
  ```

  Additionally, specifying "sinks" is also supported.  Specifying a sink is a
  way to determine what functions depend on another; e.g. if you want data on
  functions that reference `MyApp.foo/2` and functions that references those
  functions, you would write:

  ```
  $ mix viz --sink MyApp.foo/2
  ```

  Multiple sinks are supported and can be combined with sources to find paths
  from one (or more) function to another (or several).

  Export formats other than the CSV format are available.  They are:

  - `dot_hier` :: Function nodes are grouped into module nodes.  Module nodes
    are grouped by hierarchy (e.g. The `MyApp.Foo` node will be inside the
    `MyApp` node).
  - `dot` :: Function nodes are grouped into module nodes.  Module nodes are not
    grouped.
  - `dot_functions` :: Function nodes are not grouped; module nodes do not
    exist.
  - `dot_modules` :: Only connections between module nodes are shown.  Function
    nodes do not exist.
  - `json`

  Alternative formats are specified with the `--format` flag, e.g.

  ```
  $ mix viz --format dot
  ```

  The first four use the GraphViz DOT language to illustrate your call-graph.
  Once you have created a `.dot` file, you can use a GraphViz tool (e.g. `dot`)
  to visualize the call-graph:

  ```
  $ dot out.dot -Tsvg -o out.svg
  ```

  This command creates an `out.svg` file which you can view in your browser.

  The `dot` tool tries to create a heirarchy of nodes.  If this view is
  unhelpful to you, try `fdp` which uses force-directed placement to lay out
  nodes in a cluster.

  This tool currently has two "analyzers" to find function calls; "tracer" and
  "beams".  The former uses an Elixir compilation tracer to aggregate call
  events from the Elixir compiler while the application is being compiled, the
  latter analyzes the `.beam` files produced when your application is compiled
  (a la Dialyzer).  Each has strengths and weaknesses.  The beams analyzer is
  not aware of macros whereas the tracer analyzer is.  On the other hand, the
  tracer analyzer can't see when a function call is injected into a function
  *by* a macro, whereas the beams analyzer can.  Thus, the default behavior is
  to use *both* analyzers, but if you have a specific need (e.g. speed), you can
  specify only one or the other.

  To only use the "beams" analyzer (which much faster if your app is already
  compiled), invoke `mix viz` like so:

  ```
  $ mix viz --analyzer beams
  ```

  To only use the "tracer" analyzer, invoke `mix viz` like so:

  ```
  $ mix viz --analyzer tracer
  ```

  ## Command line options

  - --analyzer - Which analyzer(s) to use. Viz includes "beams" and "tracer"
      analzyers, analyzing the compiled .beam files and the compilation tracer
      output from the Elixir compiler, respectively. The default is "beams" and
      "tracer".
  - --filename - The output file name.
  - --format - Which output format to use. Viz includes "csv", "dot",
      "dot_functions", "dot_hier", "dot_modules", and "json".
  - --source - Limit analysis to one or more graph "sources",
      e.g. `Enum.map/2`. Only calls downstream from the source(s) will be
      included in the output.
  - --sink - Limit analysis to one or more graph "sinks",
      e.g. `Enum.map/2`. Only calls upstream from the sink(s) will be included
      in the output.
  """
  use Mix.Task

  @option_format [
    strict: [
      analyzer: [:string, :keep],
      filename: :string,
      format: :string,
      source: [:string, :keep],
      sink: [:string, :keep]
    ]
  ]
  @defaults [format: "CSV", analyzer: "beams", analyzer: "tracer"]

  defmodule Options do
    defstruct [:analyzers, :filename, :format, :sources, :sinks]
  end

  @shortdoc "Creates a call graph data file from the codebase"
  @impl Mix.Task
  def run(args) do
    Code.ensure_all_loaded!([Viz, Viz.Exporter.Utils])

    with {:ok,
          %Options{
            analyzers: analyzers,
            filename: filename,
            format: format,
            sources: sources,
            sinks: sinks
          }} <- parse_args(args),
         {:ok, exporter_module} <- format_to_exporter_module(format),
         {:ok, analyzers} <- load_analyzers(analyzers),
         {:ok, sources} <- parse_funs(sources),
         {:ok, sinks} <- parse_funs(sinks),
         {:ok, filename} <- Viz.run(analyzers, exporter_module, filename, sources, sinks) do
      Mix.Shell.IO.info("Call graph written to #{filename}!")
    else
      error -> print_result(error)
    end
  end

  defp parse_args(args) do
    args
    |> OptionParser.parse(@option_format)
    |> to_options()
  end

  defp to_options({opts, [], []}) do
    opts = Keyword.merge(@defaults, opts)

    with {analyzers, other_opts} = Keyword.pop_values(opts, :analyzer),
         {filename, other_opts} = Keyword.pop(other_opts, :filename),
         {format, other_opts} = Keyword.pop(other_opts, :format),
         {sources, other_opts} = Keyword.pop_values(other_opts, :source),
         {sinks, _other_opts} = Keyword.pop_values(other_opts, :sink) do
      {:ok,
       %Options{
         analyzers: analyzers,
         filename: filename,
         format: format,
         sources: sources,
         sinks: sinks
       }}
    end
  end

  defp to_options({_opts, positional, flags}), do: {:error, :bad_options, positional, flags}

  def load_analyzers(strs) do
    strs
    |> Enum.map(&format_to_analyzer_module/1)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, mod}, {:ok, analyzers} -> {:cont, {:ok, [mod | analyzers]}}
      error, _acc -> {:halt, error}
    end)
  end

  # This is dark magic, but allows for third parties to provide exporters (I think)
  defp format_to_exporter_module(str) do
    exporter =
      str
      |> Macro.camelize()
      |> then(&("Elixir.Viz.Exporter." <> &1))
      |> String.to_atom()

    with {:module, exporter} <- Code.ensure_loaded(exporter) do
      {:ok, exporter}
    else
      {:error, reason} -> {:error, :could_not_load_exporter, reason}
    end
  end

  # Same dark magic
  defp format_to_analyzer_module(str) do
    analyzer =
      str
      |> Macro.camelize()
      |> then(&("Elixir.Viz.Analyzer." <> &1))
      |> String.to_atom()

    with {:module, analyzer} <- Code.ensure_loaded(analyzer) do
      {:ok, analyzer}
    else
      {:error, reason} -> {:error, :could_not_load_analyzer, reason}
    end
  end

  defp parse_funs(sources) do
    sources
    |> Enum.map(&dehash/1)
    |> Enum.split_with(&match?({:ok, _}, &1))
    |> case do
      {[], []} -> {:ok, nil}
      {good, []} -> {:ok, Enum.map(good, &elem(&1, 1))}
      {[], bad} -> {:error, :bad_hashes, Enum.map(bad, &elem(&1, 2))}
    end
  end

  # Slightly dark magic; turns a string like "Foo.Baz.bar/2" into a psuedo MFA
  # tuple like {"Foo.Baz", :bar, 2}.
  defp dehash(str) do
    # The use of /.+/ in the regexp is to account for the extremely liberal
    # definition of Erlang's atoms.  Module and function names must only be
    # valid atoms.
    with %{"mod" => mod, "fun" => fun, "arity" => arity} <-
           Regex.named_captures(~r/(?<mod>.+)\.(?<fun>.+)\/(?<arity>\d+)/, str) do
      {:ok, {mod, String.to_atom(fun), String.to_integer(arity)}}
    else
      nil -> {:error, :parse_mfa, str}
    end
  end

  def print_result(result) do
    case result do
      {:error, :could_not_load_exporter, reason} ->
        Mix.Shell.IO.error("Could not load exporter: #{inspect(reason)}")

      {:error, :could_not_load_analyzer, reason} ->
        Mix.Shell.IO.error("Could not load analyzer: #{inspect(reason)}")

      {:error, :bad_hashes, hashes} ->
        Mix.Shell.IO.error(
          "Could not parse functions into MFA tuples: #{Enum.join(hashes, ", ")}"
        )

      {:error, :bad_options, positional, flags} ->
        if(Enum.any?(positional), do: print_positional_errors(positional))
        if(Enum.any?(flags), do: print_flag_errors(flags))

      {:error, reason} when is_atom(reason) ->
        Mix.Shell.IO.error("Failed to write output: #{reason}")
    end
  end

  defp print_positional_errors(positional) do
    Mix.Shell.IO.error("Unknown options: #{Enum.join(positional, ", ")}")
  end

  defp print_flag_errors(flags) do
    formatted =
      flags
      |> Enum.map(&elem(&1, 0))
      |> Enum.join(", ")

    Mix.Shell.IO.error("Unknown flags: #{formatted}")
  end
end
