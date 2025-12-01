defmodule Viz.MixProject do
  use Mix.Project

  def project do
    [
      app: :viz,
      version: "0.3.0",
      elixir: "~> 1.13",
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Viz.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:dialyxir, "~> 1.4.6", only: [:dev, :test], runtime: false}]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix]
    ]
  end
end
