defmodule ZoneServer.Broadcaster do
  @moduledoc """
  Accepts WebTransport connections on UDP ZONE_PORT and broadcasts
  CH_INTEREST datagrams with simulated jellyfish entities every 5 frames
  (at ~60 fps headless = ~12 broadcasts/s).

  Each entity position follows a simple sinusoidal path so the observer
  can verify movement across frames.
  """

  use GenServer
  require Logger

  @broadcast_every_ms 83   # ~12 Hz
  @entity_count 16

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 7443)
    Logger.info("[ZoneServer] Starting WebTransport broadcaster on UDP #{port}")

    # WTransport NIF starts a QUIC/WebTransport listener.
    # Returns {:ok, server_ref} or {:error, reason}.
    case :wtransport_native.start_server(port, "/") do
      {:ok, server} ->
        Logger.info("[ZoneServer] Listening on UDP #{port} path /")
        :timer.send_interval(@broadcast_every_ms, :broadcast)
        {:ok, %{server: server, tick: 0, clients: []}}

      {:error, reason} ->
        Logger.error("[ZoneServer] Failed to start server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info(:broadcast, state) do
    tick = state.tick

    entities = for i <- 0..(@entity_count - 1) do
      angle = tick * 0.05 + i * :math.pi() * 2 / @entity_count
      %{
        gid: i,
        x: :math.cos(angle) * 5.0,
        y: 0.0,
        z: :math.sin(angle) * 5.0
      }
    end

    packet = ZoneServer.Packet.encode_interest(entities)

    # Broadcast to all connected clients via datagrams.
    Enum.each(state.clients, fn client ->
      :wtransport_native.send_datagram(client, packet)
    end)

    # Accept any new connections.
    new_clients =
      case :wtransport_native.accept(state.server) do
        {:ok, client} ->
          Logger.info("[ZoneServer] Client connected (tick=#{tick})")
          [client | state.clients]
        :none ->
          state.clients
      end

    if rem(tick, 60) == 0 do
      Logger.info("[ZoneServer] tick=#{tick} clients=#{length(new_clients)} entities=#{@entity_count}")
    end

    {:noreply, %{state | tick: tick + 1, clients: new_clients}}
  end
end
