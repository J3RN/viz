defmodule Viz.Server do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  def log_event(event, env)

  def log_event(
        {remote, _meta, targetm, targetf, targeta},
        %Macro.Env{module: sourcem, function: {sourcef, sourcea}}
      )
      when remote in [:remote_function, :remote_macro] do
    do_log({sourcem, sourcef, sourcea}, {targetm, targetf, targeta})
  end

  def log_event(
        {local, _meta, targetf, targeta},
        %Macro.Env{module: sourcem, function: {sourcef, sourcea}}
      )
      when local in [:local_function, :local_macro] do
    do_log({sourcem, sourcef, sourcea}, {sourcem, targetf, targeta})
  end

  def log_event(_event, _env), do: :ok

  defp do_log({sourcem, sourcef, sourcea}, {targetm, targetf, targeta}) do
    new_entry = {
      {clean_name(sourcem), sourcef, sourcea},
      {clean_name(targetm), targetf, targeta}
    }

    Agent.update(__MODULE__, &MapSet.put(&1, new_entry))
  end

  def get_calls() do
    Agent.get(__MODULE__, & &1)
  end

  defp clean_name(module) do
    module
    |> to_string()
    |> String.trim_leading("Elixir.")
  end
end
