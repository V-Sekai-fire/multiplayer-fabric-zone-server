defmodule ZoneServer.Handler do
  @moduledoc """
  WebTransport connection handler. Registers each connection in the
  ZoneServer.ConnectionRegistry so the Ticker can broadcast to all of them.
  """
  use Wtransport.ConnectionHandler
  require Logger

  @impl Wtransport.ConnectionHandler
  def handle_connection(%Wtransport.Connection{} = conn, state) do
    Logger.info("[ZoneServer] client connected stable_id=#{conn.stable_id}")
    Registry.register(ZoneServer.ConnectionRegistry, :connection, conn)
    {:continue, state}
  end

  @impl Wtransport.ConnectionHandler
  def handle_datagram(_dgram, _conn, state) do
    {:continue, state}
  end

  @impl Wtransport.ConnectionHandler
  def handle_close(%Wtransport.Connection{} = conn, state) do
    Logger.info("[ZoneServer] client disconnected stable_id=#{conn.stable_id}")
    state
  end
end
