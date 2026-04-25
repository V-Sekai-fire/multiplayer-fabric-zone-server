defmodule ZoneServer.Packet do
  @moduledoc """
  CH_INTEREST packet encoder.

  Layout (100 bytes per entity):
    [u32 gid(4)][f64 cx(8)][f64 cy(8)][f64 cz(8)]
    [i16 vx(2)][i16 vy(2)][i16 vz(2)][i16 ax(2)][i16 ay(2)][i16 az(2)]
    [u32 hlc(4)][u32×14 payload(56)]
  """

  @entry_size 100

  def encode_interest(entities) when is_list(entities) do
    Enum.reduce(entities, <<>>, fn e, acc ->
      acc <> encode_entry(e)
    end)
  end

  defp encode_entry(%{gid: gid, x: x, y: y, z: z}) do
    <<
      gid::little-unsigned-32,
      x::little-float-64,
      y::little-float-64,
      z::little-float-64,
      # vel/accel: zero
      0::little-signed-16, 0::little-signed-16, 0::little-signed-16,
      0::little-signed-16, 0::little-signed-16, 0::little-signed-16,
      # hlc: zero
      0::little-unsigned-32,
      # payload[0]: entity_class=0 (jellyfish), owner=0, state=0
      0::little-unsigned-32,
      # payload[1..13]: zero
      0::little-unsigned-32, 0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32
    >>
  end

  def entry_size, do: @entry_size
end
