defmodule Mixite.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Exampple, [otp_app: :mixite]}
    ]

    opts = [strategy: :one_for_one, name: Mixite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
