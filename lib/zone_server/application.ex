defmodule ZoneServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = System.get_env("ZONE_PORT", "7443") |> String.to_integer()

    children = [
      {ZoneServer.Broadcaster, port: port}
    ]

    opts = [strategy: :one_for_one, name: ZoneServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
