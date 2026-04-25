/-!
# CH_INTEREST Packet Layout

Proves that the CH_INTEREST / CH_PLAYER 100-byte layout is internally
consistent: header fields sum to exactly `PAYLOAD_OFFSET`, and
header + payload sum to exactly `PACKET_SIZE`.

Layout:
  Offset   Size  Field
       0      4  gid        (uint32, little-endian)
       4      8  cx         (float64, little-endian)
      12      8  cy         (float64, little-endian)
      20      8  cz         (float64, little-endian)
      28      2  vx         (int16, scale 1/V_SCALE)
      30      2  vy
      32      2  vz
      34      2  ax         (int16, scale 1/A_SCALE)
      36      2  ay
      38      2  az
      40      4  hlc        (uint32: tick[23:0] | counter[7:0])
      44     56  payload    (uint32 × 14)
     100      —  end
-/

set_option autoImplicit false

-- ---------------------------------------------------------------------------
-- Field sizes (bytes)
-- ---------------------------------------------------------------------------

def sz_gid    : Nat :=  4   -- uint32
def sz_cx     : Nat :=  8   -- float64
def sz_cy     : Nat :=  8
def sz_cz     : Nat :=  8
def sz_vx     : Nat :=  2   -- int16
def sz_vy     : Nat :=  2
def sz_vz     : Nat :=  2
def sz_ax     : Nat :=  2   -- int16
def sz_ay     : Nat :=  2
def sz_az     : Nat :=  2
def sz_hlc    : Nat :=  4   -- uint32
def sz_payload : Nat := 56  -- uint32 × 14

-- ---------------------------------------------------------------------------
-- Derived constants
-- ---------------------------------------------------------------------------

def PAYLOAD_OFFSET : Nat :=
  sz_gid + sz_cx + sz_cy + sz_cz +
  sz_vx + sz_vy + sz_vz +
  sz_ax + sz_ay + sz_az +
  sz_hlc

def PACKET_SIZE : Nat := PAYLOAD_OFFSET + sz_payload

-- ---------------------------------------------------------------------------
-- Proofs
-- ---------------------------------------------------------------------------

theorem payload_offset_is_44 : PAYLOAD_OFFSET = 44 := by decide

theorem packet_size_is_100 : PACKET_SIZE = 100 := by decide

theorem payload_fits : PAYLOAD_OFFSET + sz_payload = PACKET_SIZE := by decide

/-- 14 uint32 words occupy exactly 56 bytes. -/
theorem payload_word_count : 14 * 4 = sz_payload := by decide

/-- Every entity entry is exactly 100 bytes. -/
theorem entry_size_exact : PACKET_SIZE = 100 := by decide

/-- For a buffer of N entities the total size is N × 100. -/
theorem multi_entry_size (n : Nat) : n * PACKET_SIZE = n * 100 := by
  simp [packet_size_is_100]
