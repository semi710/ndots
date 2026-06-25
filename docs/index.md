# ndots

A declarative **NixOS + nix-darwin** configuration built with [flakes](https://nixos.wiki/wiki/Flakes), modularized via [Flake-Parts](https://flake.parts), and auto-wired with [nix-wire](https://github.com/semi710/nix-wire).

Fully CLI-based — all hosts are managed via SSH + Tailscale. No GUI required for administration.

## At a Glance

| | |
|---|---|
| **Platforms** | NixOS (Linux), nix-darwin (macOS) |
| **Build System** | Flakes + Flake-Parts + nix-wire |
| **Disk Management** | disko (declarative partitioning) |
| **Secrets** | sops-nix (age encryption) |
| **Networking** | Tailscale mesh VPN |
| **Monitoring** | Beszel hub + agents |
| **Deployment** | `just deploy` (auto-detects NixOS vs Darwin) |

## Hosts

| Host | CPU | RAM | Role |
|------|-----|-----|------|
| **mach** | Intel i7-10510U (4c/8t) | 24 GB | Personal laptop |
| **dsd** | Intel i9-12900KS (16c/24t) | 64 GB | Work desktop |
| **semi** | Intel i9-14900K (24c/32t) | 128 GB | Semi-personal |
| **obox** | Ampere Neoverse-N1 (4c/4t) | 24 GB | Oracle Cloud VPS |
| **jp-mbp** | Apple M4 | — | MacBook Pro |

See [Hosts](hosts/index.md) for per-host details.

## Services

- [Beszel](services/beszel.md) — system monitoring hub + agents
- [Stirling PDF](services/stirling-pdf.md) — self-hosted PDF tools
- [FileBrowser Quantum](services/filebrowser.md) — web file manager
- [Caddy](services/caddy.md) — reverse proxy
- [Syncthing](services/syncthing.md) — cross-device file sync
- [Tailscale](services/tailscale.md) — mesh VPN
- [Docker & Podman](services/docker.md) — container runtimes

## Quick Start

```bash
# Deploy to current host
just deploy

# Deploy to a remote host
just deploy obox

# Build ISO installer
just iso
```

See [Deployment](guides/deployment.md) for full details.
