# LLM Context

This file maintains the current state of the ndots project for LLM assistants. Update it when making significant changes.

## Goal

Declarative NixOS + nix-darwin configuration with self-hosted services, monitoring, and mesh VPN. All managed via flakes, deployed with `just`.

## Constraints & Preferences

- **Ponytail mode** (lazy senior dev) — minimal code, no over-engineering
- No clutter comments (no `---` dividers, no ASCII art), comments explain why not what
- Secrets: `office.yaml` for office machines, `server.yaml` for servers
- Sops modules only enable services; hosts declare secrets and wire paths
- Caddy config is imperative (editable on the box, no rebuild)
- `just deploy` auto-detects NixOS vs Darwin; `just deploy <host>` for remote
- Don't commit until tested and verified
- Service ports in 4xxx range to avoid clashes

## Current State

### Done
- Beszel hub on obox, agents on semi/dsd/obox/mach
- FileBrowser Quantum on all NixOS hosts (root, Tailscale-only, sops passwords)
- Stirling PDF on obox (branded "semi.sh PDF", update notifications off)
- Caddy on obox (imperative config)
- Syncthing: `.notes` + `.dump` synced across all devices
- Tailscale on all hosts
- Shared virtualisation module (docker system+rootless, podman)
- Opencode config reorganized (default.nix, skills.nix, registry.nix)
- Docs site (MkDocs Material, GitHub Pages, ndots.semi.sh)

### Deferred
- Excalidraw (docker + room server) — deferred, not deployed
- Stirling PDF Google Drive integration — paid feature, not configured

## Key Gotchas

- `config.users.users.<name>.uid` causes infinite recursion in NixOS eval — use hardcoded 1000
- Syncthing doesn't expand `~` — use `config.home.homeDirectory` for absolute paths
- Stirling PDF env-based admin only works on first boot with empty DB
- Beszel agent needs to run as user for rootless Docker (0700 on `/run/user/<uid>/`)
- AMD GPU bug: SKIP_GPU=true on mach (beszel issue #1799)
- `podman.dockerSocket.enable` conflicts with `docker.enable`
- `oci-containers` defaults to podman if both enabled — set `backend = "docker"` to force
- Excalidraw `REACT_APP_BACKEND_V2_WS_BASE_URL` is browser-side — must be public URL
- FileBrowser Quantum indexing `/` can fail if DB is corrupt — clear `/var/lib/filebrowser-quantum/*`
