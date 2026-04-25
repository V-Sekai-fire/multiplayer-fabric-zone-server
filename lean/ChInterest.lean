/-!
# CH_INTEREST Packet Layout + WTD Frame Version

Proves two things:

1. The 100-byte CH_INTEREST / CH_PLAYER entry layout is internally consistent.
2. The protocol version fits in bits [7:4] of the WTD frame flag byte (zero
   extra bytes — pure bitcrushing into the previously-reserved nibble).

## Entry layout (100 bytes)

  Offset   Size  Field
       0      4  gid        (uint32, little-endian)
       4      8  cx         (float64, little-endian)
      12      8  cy
      20      8  cz
      28      2  vx         (int16, V_SCALE)
      30      2  vy
      32      2  vz
      34      2  ax         (int16, A_SCALE)
      36      2  ay
      38      2  az
      40      4  hlc        (uint32: tick[23:0] | counter[7:0])
      44     56  payload    (uint32 × 14)
     100      —  end

## WTD frame flag byte (1 byte, outside the 100-byte entry)

  bit 0   : 0 = reliable (WT bidi stream), 1 = unreliable (WT datagram)
  bits 1-3: channel (0-7); CH_INTEREST = 2
  bits 4-7: protocol version (0-15); current = 1

  CH_INTEREST v1 unreliable: flag = (1 << 4) | (2 << 1) | 1 = 0x15
-/

set_option autoImplicit false

-- ---------------------------------------------------------------------------
-- § 1  Entry layout
-- ---------------------------------------------------------------------------

def sz_gid     : Nat :=  4
def sz_cx      : Nat :=  8
def sz_cy      : Nat :=  8
def sz_cz      : Nat :=  8
def sz_vx      : Nat :=  2
def sz_vy      : Nat :=  2
def sz_vz      : Nat :=  2
def sz_ax      : Nat :=  2
def sz_ay      : Nat :=  2
def sz_az      : Nat :=  2
def sz_hlc     : Nat :=  4
def sz_payload : Nat := 56   -- uint32 × 14

def PAYLOAD_OFFSET : Nat :=
  sz_gid + sz_cx + sz_cy + sz_cz +
  sz_vx + sz_vy + sz_vz +
  sz_ax + sz_ay + sz_az +
  sz_hlc

def PACKET_SIZE : Nat := PAYLOAD_OFFSET + sz_payload

theorem payload_offset_is_44 : PAYLOAD_OFFSET = 44 := by decide
theorem packet_size_is_100   : PACKET_SIZE = 100   := by decide
theorem payload_fits         : PAYLOAD_OFFSET + sz_payload = PACKET_SIZE := by decide
theorem payload_word_count   : 14 * 4 = sz_payload := by decide

/-- N entities occupy exactly N × 100 bytes. -/
theorem multi_entry_size (n : Nat) : n * PACKET_SIZE = n * 100 := by
  simp [packet_size_is_100]

-- ---------------------------------------------------------------------------
-- § 2  WTD frame flag byte — version bitpacking
-- ---------------------------------------------------------------------------

/-- The flag byte has 8 bits; bits 4-7 hold the version (0-15). -/
def FLAG_BITS        : Nat := 8
def VERSION_SHIFT    : Nat := 4
def VERSION_MASK     : Nat := 0x0F   -- 4 bits
def CHANNEL_SHIFT    : Nat := 1
def CHANNEL_MASK     : Nat := 0x07   -- 3 bits

/-- Build a flag byte from version, channel, and reliability. -/
def mkFlag (version channel : Nat) (unreliable : Bool) : Nat :=
  (version &&& VERSION_MASK) <<< VERSION_SHIFT |||
  (channel &&& CHANNEL_MASK) <<< CHANNEL_SHIFT |||
  (if unreliable then 1 else 0)

/-- CH_INTEREST (channel 2), unreliable, protocol version 1 → 0x15. -/
theorem ch_interest_v1_flag : mkFlag 1 2 true = 0x15 := by decide

/-- The flag byte always fits in one byte (< 256). -/
theorem flag_fits_byte (v c : Nat) (u : Bool)
    (hv : v < 16) (hc : c < 8) : mkFlag v c u < 256 := by
  simp [mkFlag]
  omega

/-- Extracting the version from a flag byte recovers the original value. -/
theorem version_roundtrip (v : Nat) (hv : v < 16) :
    (mkFlag v 0 false >>> VERSION_SHIFT) &&& VERSION_MASK = v := by
  simp [mkFlag, VERSION_SHIFT, VERSION_MASK, CHANNEL_SHIFT, CHANNEL_MASK]
  omega

/-- Version and channel fields do not overlap. -/
theorem version_channel_disjoint (v c : Nat) (u : Bool)
    (hv : v < 16) (hc : c < 8) :
    (mkFlag v c u &&& 0xF0) >>> VERSION_SHIFT = v := by
  simp [mkFlag, VERSION_SHIFT, VERSION_MASK, CHANNEL_SHIFT, CHANNEL_MASK]
  omega
