defmodule ZoneServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :zone_server,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ZoneServer.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:wtransport, github: "V-Sekai-fire/multiplayer-fabric-webtransport"}
    ]
  end
end
