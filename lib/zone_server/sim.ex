defmodule ZoneServer.Sim do
  @moduledoc """
  Pure Elixir entity simulation — jellyfish bloom physics.

  Mirrors FabricZone::_step_entity (SCENARIO_JELLYFISH_BLOOM) from the
  Godot reference implementation. Independent second implementation.
  """

  @sim_hz      60
  @v_max       0.3
  @beat_period @sim_hz * 1          # 1 s
  @beat_on     max(div(80 * @sim_hz, 1000), 1)

  @type entity :: %{
    gid: non_neg_integer(),
    cx: float(), cy: float(), cz: float(),
    vx: float(), vy: float(), vz: float(),
    ax: float(), ay: float(), az: float()
  }

  @doc "Advance one entity by one tick using jellyfish bloom physics."
  @spec step(entity(), non_neg_integer()) :: entity()
  def step(%{gid: gid, cx: cx, cy: cy, cz: cz,
             vx: vx, vy: vy, vz: vz} = e, tick) do
    rx = -(cx / 0.8)
    ry = -(cy / 0.8)
    beat = rem(tick, @beat_period) < @beat_on
    beat_ax = if beat, do: -(cx / 0.2), else: 0.0
    beat_ay = if beat, do: -(cy / 0.2), else: 0.0
    gate = rem((tick * 7 + gid * 13), 8) == 0
    kx = if gate, do: (rem(tick * 3 + gid * 11, 25) - 12) * 0.001, else: 0.0
    ky = if gate, do: (rem(tick * 5 + gid * 17, 25) - 12) * 0.001, else: 0.0

    nvx = clamp(vx + kx + rx + beat_ax, -@v_max, @v_max)
    nvy = clamp(vy + ky + ry + beat_ay, -@v_max, @v_max)
    nvz = clamp(vz, -0.1, 0.1)
    {ncx, nnvx} = bounce(cx + nvx, nvx, 3.0)
    {ncy, nnvy} = bounce(cy + nvy, nvy, 3.0)
    {ncz, nnvz} = bounce(cz + nvz, nvz, 0.3)

    %{e |
      cx: ncx, cy: ncy, cz: ncz,
      vx: nnvx, vy: nnvy, vz: nnvz,
      ax: nnvx - vx, ay: nnvy - vy, az: nnvz - vz}
  end

  @doc "Create default entity at index i, spread in a circle."
  @spec new(non_neg_integer(), non_neg_integer()) :: entity()
  def new(gid, total) do
    angle = gid * :math.pi() * 2.0 / total
    %{gid: gid,
      cx: :math.cos(angle) * 2.0, cy: 0.0, cz: :math.sin(angle) * 2.0,
      vx: 0.0, vy: 0.0, vz: 0.0,
      ax: 0.0, ay: 0.0, az: 0.0}
  end

  defp clamp(v, lo, _hi) when v < lo, do: lo
  defp clamp(v, _lo, hi) when v > hi, do: hi
  defp clamp(v, _lo, _hi), do: v

  defp bounce(pos, vel, bound) when pos > bound,  do: {2.0 * bound - pos, -vel}
  defp bounce(pos, vel, bound) when pos < -bound, do: {-2.0 * bound - pos, -vel}
  defp bounce(pos, vel, _bound), do: {pos, vel}
end
