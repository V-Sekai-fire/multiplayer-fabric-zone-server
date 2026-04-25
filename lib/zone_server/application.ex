defmodule ZoneServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = System.get_env("ZONE_PORT", "7443") |> String.to_integer()
    host = System.get_env("ZONE_HOST", "0.0.0.0")
    priv = :code.priv_dir(:zone_server) |> List.to_string()
    certfile = System.get_env("ZONE_CERTFILE", Path.join(priv, "cert.pem"))
    keyfile  = System.get_env("ZONE_KEYFILE",  Path.join(priv, "key.pem"))

    children = [
      {Registry, keys: :duplicate, name: ZoneServer.ConnectionRegistry},
      {ZoneServer.Ticker, []},
      {Wtransport.Supervisor,
        host: host,
        port: port,
        certfile: certfile,
        keyfile: keyfile,
        connection_handler: ZoneServer.Handler,
        log_network_data: false,
        name: ZoneServer.WtSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ZoneServer.Supervisor)
  end
end
