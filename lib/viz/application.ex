defmodule Viz.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Viz.Server, []}
    ]

    opts = [strategy: :one_for_one, name: Viz.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
