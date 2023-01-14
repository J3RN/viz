defmodule Viz.Exporter.Utils do
  @moduledoc """
  Various utilities for the construction of exporters.
  """

  def hash({m, f, a}), do: "#{m}.#{f}/#{a}"
end
