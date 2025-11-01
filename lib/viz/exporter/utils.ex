defmodule Viz.Exporter.Utils do
  @moduledoc """
  Various utilities for the construction of exporters.
  """

  @doc ~S"""
  Turn an MFA tuple (where the module is a string) into a string of the format
  m.f/a

  ## Examples

      iex> Viz.Exporter.Utils.hash({"Foo", :bar, 2})
      "Foo.bar/2"

  """
  @spec hash({String.t(), atom, integer}) :: String.t()
  def hash({m, f, a}), do: "#{m}.#{f}/#{a}"

  @spec fhash(atom, integer) :: String.t()
  def fhash(f, a), do: "#{f}/#{a}"
end
