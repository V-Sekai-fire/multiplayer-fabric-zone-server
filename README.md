# multiplayer-fabric-zone-server

Elixir WebTransport zone server — second implementation of the zone server
alongside the Godot-native zone server.

| Dimension | This repo | Godot zone server |
|---|---|---|
| Language | Elixir + wtransport Rust NIF | GDScript + C++ (picoquic) |
| Transport | wtransport (independent QUIC stack) | picoquic |
| Physics | Pure Elixir jellyfish bloom | C++ FabricZone |
| Port | UDP 7443 | UDP 7443 |

## Prerequisites

- Elixir 1.19 / OTP 28
- Rust (for the `wtransport` NIF — transport layer only)
- `multiplayer-fabric-hosting/generate-secrets.sh` run at least once
  (generates `certs/zone-server.crt` and `certs/zone-server.key`)

## TLS cert

`priv/cert.pem` and `priv/key.pem` are **symlinks** into
`../multiplayer-fabric-hosting/certs/`. Generate them with:

```sh
cd ../multiplayer-fabric-hosting
./generate-secrets.sh
```

The script creates a 14-day self-signed P-256 cert — the maximum validity
allowed by the WebTransport spec for browser cert-hash pinning.

## Running locally

```sh
# 1. Generate cert (once, or after 14 days)
cd ../multiplayer-fabric-hosting && ./generate-secrets.sh && cd -

# 2. Start zone server
ZONE_PORT=7443 mix run --no-halt
```

## Testing with the observer

From `multiplayer-fabric-hosting/`:

```sh
# Start zone server in one terminal
cd ../multiplayer-fabric-zone-server && ZONE_PORT=7443 mix run --no-halt

# Run observer in another
just go-test
```

`go-test` runs `headless_log_observer.gd` against `127.0.0.1:7443` and
asserts `entities > 0` from `--dump-json` output.

## Architecture

```
ZoneServer.Application
  ├── Registry (connection tracking)
  ├── Wtransport.Supervisor (WebTransport listener, UDP 7443)
  │     └── ZoneServer.Handler per connection
  │           registers conn in Registry
  └── ZoneServer.Ticker (~12 Hz)
        ZoneServer.Sim.step/2  — pure Elixir jellyfish physics
        ZoneServer.Packet      — 100-byte CH_INTEREST encoding
        ZoneServer.PBVH (TODO) — Hilbert AOI spatial index
        broadcasts WTD-framed datagrams to all registered connections
```

## Packet format

See `lean/ChInterest.lean` for the machine-checked proof of the 100-byte
layout and WTD frame version bitpacking (`flag=0x15`: version=1, channel=2,
unreliable).
