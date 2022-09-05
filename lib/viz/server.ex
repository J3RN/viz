defmodule Viz.Server do
  use GenServer, shutdown: 1_000

  # Client
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(init) do
    IO.puts("Starting!")
    {:ok, MapSet.new(init)}
  end

  def handle_call(event, from, state)

  def handle_call({{:remote_function, _meta, module, _name, _arity}, env}, _from, state) do
    target = clean_name(module)
    source = clean_name(env.module)

    # cond do
    #   # Ignore Erlang modules (for now at least)
    #   not capitalized?(target) ->
    #     {:reply, :ok, state}

    #   true ->
        {:reply, :ok, MapSet.put(state, "\"#{source}\" -> \"#{target}\"")}
    # end
  end

  def handle_call({:stop, _env}, _from, state) do
    write_state(state)
    {:reply, :ok, state}
  end

  def handle_call(_event, _from, state) do
    {:reply, :ok, state}
  end

  defp write_state(state) do
    body = Enum.join(state, "\n")

    File.write("out.dot", """
    digraph {
    #{body}
    }
    """)
  end

  defp clean_name(module) do
    module
    |> to_string()
    |> String.trim_leading("Elixir.")
  end

  defp capitalized?(name) do
    name == String.capitalize(name)
  end
end
