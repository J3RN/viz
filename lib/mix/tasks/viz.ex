defmodule Mix.Tasks.Viz do
  @moduledoc "The mix task Viz"
  use Mix.Task

  @shortdoc "Creates a call graph data file from the codebase"
  @impl Mix.Task
  def run(args) do
    with {opts, [], []} <- parse_args(args),
         {format, other_opts} = Keyword.pop(opts, :format, "CSV"),
         {slices, other_opts} = Keyword.pop_values(other_opts, :slice),
         {:ok, exporter_module} <- format_to_exporter_module(format),
         {:ok, slices} <- parse_slices(slices),
         {:ok, filename} <- do_run(exporter_module, [{:slices, slices} | other_opts]) do
      Mix.Shell.IO.info("Call graph written to #{filename}!")
    else
      error -> print_result(error)
    end
  end

  defp parse_args(args) do
    OptionParser.parse(args, strict: [filename: :string, format: :string, slice: [:string, :keep]])
  end

  defp do_run(exporter, opts) do
    :ok = Application.ensure_started(:viz)
    Mix.Task.run("compile", ["--force", "--tracer", "Viz"])
    Viz.export(exporter, opts)
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

  defp parse_slices(slices) do
    slices
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
          "Could not parse slice sources into MFA tuples: #{Enum.join(hashes, ", ")}"
        )

      {:error, :unknown_options, opt_names} ->
        Mix.Shell.IO.error("Unknown options: #{Enum.join(opt_names, ", ")}")

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
