defmodule ZoneServer.Ticker do
  @moduledoc """
  Advances entity simulation each tick and broadcasts CH_INTEREST datagrams
  to all registered connections at ~12 Hz.

  WTD frame flag: version=1 (bits 4-7), channel=2 (bits 1-3), unreliable (bit 0)
  flag = (1 << 4) | (2 << 1) | 1 = 0x15
  Proved in lean/ChInterest.lean :: ch_interest_v1_flag
  """
  use GenServer
  import Bitwise
  require Logger

  @interval_ms  83    # ~12 Hz
  @entity_count 16
  @ch_interest_flag 0x15   # version=1, channel=2, unreliable

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    entities = for i <- 0..(@entity_count - 1), do: ZoneServer.Sim.new(i, @entity_count)
    :timer.send_interval(@interval_ms, :tick)
    {:ok, %{tick: 0, entities: entities}}
  end

  @impl true
  def handle_info(:tick, %{tick: tick, entities: entities} = state) do
    entities = Enum.map(entities, &ZoneServer.Sim.step(&1, tick))
    packet   = build_packet(entities)
    broadcast(packet, tick)
    {:noreply, %{state | tick: tick + 1, entities: entities}}
  end

  defp broadcast(packet, tick) do
    conns = Registry.lookup(ZoneServer.ConnectionRegistry, :connection)
    if conns != [] && rem(tick, 60) == 0 do
      Logger.info("[ZoneServer] tick=#{tick} clients=#{length(conns)}")
    end
    Enum.each(conns, fn {_pid, conn} ->
      Wtransport.Connection.send_datagram(conn, packet)
    end)
  end

  defp build_packet(entities) do
    payload = ZoneServer.Packet.encode_interest(entities)
    <<@ch_interest_flag>> <> quic_varint(byte_size(payload)) <> payload
  end

  defp quic_varint(v) when v < 64,             do: <<v>>
  defp quic_varint(v) when v < 16_384,          do: <<0x40 ||| (v >>> 8), v &&& 0xFF>>
  defp quic_varint(v) when v < 1_073_741_824,   do: <<0x80 ||| (v >>> 24), (v >>> 16) &&& 0xFF, (v >>> 8) &&& 0xFF, v &&& 0xFF>>
  defp quic_varint(v),                           do: <<0xC0 ||| (v >>> 56), (v >>> 48) &&& 0xFF, (v >>> 40) &&& 0xFF, (v >>> 32) &&& 0xFF, (v >>> 24) &&& 0xFF, (v >>> 16) &&& 0xFF, (v >>> 8) &&& 0xFF, v &&& 0xFF>>
end
