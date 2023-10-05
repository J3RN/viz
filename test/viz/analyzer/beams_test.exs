defmodule Viz.Analyzer.BeamsTest do
  # I usually hate writing tests at this low of a level, but in this case it's
  # just easier.  I may reconstruct these later.

  use ExUnit.Case, async: true
  alias Viz.Analyzer

  setup_all do
    {calls, _output} =
      ExUnit.CaptureIO.with_io(fn ->
        Analyzer.Beams.calls_in_file('test/support/Elixir.Foobar.beam')
      end)

    %{calls: calls}
  end

  test "basic remote case", %{calls: calls} do
    assert {{"Foobar", :a, 1}, {"String", :capitalize, 1}} in calls
  end

  test "basic local case", %{calls: calls} do
    assert {{"Foobar", :b, 0}, {"Foobar", :a, 1}} in calls
  end

  test "remote reference", %{calls: calls} do
    assert {{"Foobar", :c, 0}, {"String", :capitalize, 2}} in calls
  end

  test "local reference", %{calls: calls} do
    assert {{"Foobar", :d, 0}, {"Foobar", :b, 0}} in calls
  end

  test "applied remote reference", %{calls: calls} do
    assert {{"Foobar", :f, 0}, {"String", :capitalize, 1}} in calls
  end

  test "applied local reference", %{calls: calls} do
    assert {{"Foobar", :g, 0}, {"Foobar", :a, 1}} in calls
  end
end
