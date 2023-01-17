defmodule Viz.Exporter do
  @moduledoc """
  The behaviour that all exporters should implement.

  Modules is used by `use`ing it, e.g.

  Examples

      defmodule Viz.Exporter.MyExporter do
        use Viz.Exporter

        @impl Viz.Exporter
        def export(mappings) do
          # Your logic to turn mappings into a string here
        end
      end
  """

  @callback export(MapSet.t({mfa, mfa})) :: String.t()
  @callback default_filename() :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Viz.Exporter
      import Viz.Exporter.Utils
    end
  end
end
