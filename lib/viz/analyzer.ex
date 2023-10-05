defmodule Viz.Analyzer do
  @moduledoc """
  A behaviour describing the functionality of analyzers.
  """

  # It feels weird passing *nothing* here, but the analyzers that I've written
  # pull the information they need from the environment.
  @callback analyze() :: Viz.calls()
end
