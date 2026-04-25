defmodule ZoneServer.Packet do
  @moduledoc """
  CH_INTEREST packet encoder — 100 bytes per entity.
  Layout proved in lean/ChInterest.lean.

    Offset  Size  Field
         0     4  gid        uint32 LE
         4     8  cx         float64 LE
        12     8  cy
        20     8  cz
        28     2  vx         int16 LE (V_SCALE)
        30     2  vy
        32     2  vz
        34     2  ax
        36     2  ay
        38     2  az
        40     4  hlc        uint32 LE
        44    56  payload    uint32 × 14
       100     —  end
  """

  @v_scale 32767.0 / (500_000.0 * 1.0e-6)

  def encode_interest(entities) when is_list(entities) do
    Enum.reduce(entities, <<>>, fn e, acc -> acc <> encode_entry(e) end)
  end

  defp encode_entry(%{gid: gid, cx: cx, cy: cy, cz: cz,
                      vx: vx, vy: vy, vz: vz,
                      ax: ax, ay: ay, az: az}) do
    <<
      gid::little-unsigned-32,
      cx::little-float-64,
      cy::little-float-64,
      cz::little-float-64,
      clamp16(round(vx * @v_scale))::little-signed-16,
      clamp16(round(vy * @v_scale))::little-signed-16,
      clamp16(round(vz * @v_scale))::little-signed-16,
      clamp16(round(ax * @v_scale))::little-signed-16,
      clamp16(round(ay * @v_scale))::little-signed-16,
      clamp16(round(az * @v_scale))::little-signed-16,
      0::little-unsigned-32,
      0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32, 0::little-unsigned-32,
      0::little-unsigned-32
    >>
  end

  defp clamp16(v) when v >  32767, do:  32767
  defp clamp16(v) when v < -32767, do: -32767
  defp clamp16(v), do: v
end
