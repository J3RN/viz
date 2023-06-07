defmodule Mix.Tasks.Viz do
  @moduledoc "The mix task Viz"
  use Mix.Task

  @defaults [format: "CSV"]

  defmodule Options do
    defstruct [:filename, :format, :sources, :sinks]
  end

  @shortdoc "Creates a call graph data file from the codebase"
  @impl Mix.Task
  def run(args) do
    with %Options{filename: filename, format: format, sources: sources, sinks: sinks} <-
           parse_args(args),
         {:ok, exporter_module} <- format_to_exporter_module(format),
         {:ok, sources} <- parse_funs(sources),
         {:ok, sinks} <- parse_funs(sinks),
         {:ok, filename} <- do_run(exporter_module, filename, sources, sinks) do
      Mix.Shell.IO.info("Call graph written to #{filename}!")
    else
      error -> print_result(error)
    end
  end

  defp parse_args(args) do
    OptionParser.parse(args,
      strict: [
        filename: :string,
        format: :string,
        source: [:string, :keep],
        sink: [:string, :keep]
      ]
    )
    |> to_options()
  end

  defp to_options({opts, [], []}) do
    with opts <- Keyword.merge(@defaults, opts),
         {filename, other_opts} = Keyword.pop(opts, :filename),
         {format, other_opts} = Keyword.pop(other_opts, :format),
         {sources, other_opts} = Keyword.pop_values(other_opts, :source),
         {sinks, _other_opts} = Keyword.pop_values(other_opts, :sink) do
      %Options{
        filename: filename,
        format: format,
        sources: sources,
        sinks: sinks
      }
    end
  end

  defp to_options(tuple), do: tuple

  defp do_run(exporter, filename, sources, sinks) do
    :ok = Application.ensure_started(:viz)
    Mix.Task.run("compile", ["--force", "--tracer", "Viz"])
    Viz.export(exporter, filename, sources, sinks)
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

      {:error, :bad_hashes, hashes} ->
        Mix.Shell.IO.error(
          "Could not parse functions into MFA tuples: #{Enum.join(hashes, ", ")}"
        )

      {_opts, positional, flags} ->
        if(Enum.any?(positional), do: print_positional_errors(positional))
        if(Enum.any?(flags), do: print_flag_errors(flags))
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
