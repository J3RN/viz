defmodule Viz.MixProject do
  use Mix.Project

  def project do
    [
      app: :viz,
      version: "0.2.0",
      elixir: "~> 1.13",
      deps: deps()
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
    []
  end
end
