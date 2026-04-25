defmodule ZoneServer.Ticker do
  @moduledoc """
  Broadcasts CH_INTEREST datagrams to all connected clients every ~83 ms (~12 Hz).

  Frame format (webtransportd frame.h):
    flag    = 0x05  # channel=2 (CH_INTEREST), unreliable: (2 << 1) | 1
    varint  = QUIC-style length of payload
    payload = N × 100-byte CH_INTEREST entries
  """
  use GenServer
  require Logger

  @interval_ms 83
  @entity_count 16

  # CH_INTEREST channel = 2, unreliable bit = 1 → flag = (2 << 1) | 1 = 5
  @ch_interest_flag 0x05

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    :timer.send_interval(@interval_ms, :tick)
    {:ok, 0}
  end

  @impl true
  def handle_info(:tick, tick) do
    packet = build_packet(tick)
    broadcast(packet, tick)
    {:noreply, tick + 1}
  end

  defp broadcast(packet, tick) do
    connections =
      Registry.lookup(ZoneServer.ConnectionRegistry, :connection)

    if connections != [] && rem(tick, 60) == 0 do
      Logger.info("[ZoneServer] tick=#{tick} broadcasting to #{length(connections)} clients")
    end

    Enum.each(connections, fn {_pid, conn} ->
      Wtransport.Connection.send_datagram(conn, packet)
    end)
  end

  defp build_packet(tick) do
    entities =
      for i <- 0..(@entity_count - 1) do
        angle = tick * 0.05 + i * :math.pi() * 2 / @entity_count
        %{gid: i, x: :math.cos(angle) * 5.0, y: 0.0, z: :math.sin(angle) * 5.0}
      end

    payload = ZoneServer.Packet.encode_interest(entities)
    frame(@ch_interest_flag, payload)
  end

  # Encode flag | QUIC varint(len) | payload
  defp frame(flag, payload) do
    len = byte_size(payload)
    <<flag>> <> quic_varint(len) <> payload
  end

  import Bitwise

  # QUIC-style varint (RFC 9000 §16)
  defp quic_varint(v) when v < 64,
    do: <<v>>
  defp quic_varint(v) when v < 16_384,
    do: <<0x40 ||| (v >>> 8), v &&& 0xFF>>
  defp quic_varint(v) when v < 1_073_741_824,
    do: <<0x80 ||| (v >>> 24), (v >>> 16) &&& 0xFF, (v >>> 8) &&& 0xFF, v &&& 0xFF>>
  defp quic_varint(v),
    do: <<0xC0 ||| (v >>> 56), (v >>> 48) &&& 0xFF, (v >>> 40) &&& 0xFF, (v >>> 32) &&& 0xFF,
          (v >>> 24) &&& 0xFF, (v >>> 16) &&& 0xFF, (v >>> 8) &&& 0xFF, v &&& 0xFF>>
end
