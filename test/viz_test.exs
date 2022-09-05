defmodule VizTest do
  use ExUnit.Case
  doctest Viz

  test "greets the world" do
    assert Viz.hello() == :world
  end
end
