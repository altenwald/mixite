defmodule Mixite.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Mixite.EventManager, []},
      {Mixite.Listener.Message, []}
    ]

    opts = [strategy: :one_for_one, name: Mixite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
