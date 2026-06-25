# Services

Self-hosted services running across the NixOS fleet. All services are Tailscale-only unless explicitly exposed via Caddy on obox.

| Service | Host | Access | Module |
|---------|------|--------|--------|
| [Beszel](beszel.md) | obox (hub) + all (agents) | Tailscale | `modules/nixos/beszel.nix` |
| [Stirling PDF](stirling-pdf.md) | obox | Caddy (public) | NixOS native |
| [FileBrowser Quantum](filebrowser.md) | All NixOS hosts | Tailscale | `modules/nixos/filebrowser.nix` |
| [Caddy](caddy.md) | obox | Public (80/443) | NixOS native |
| [Syncthing](syncthing.md) | All devices | Tailscale | `modules/home/syncthing.nix` |
| [Tailscale](tailscale.md) | All hosts | - | `modules/nixos/tailscale.nix` |
| [Docker & Podman](docker.md) | obox, semi, dsd, mach | - | `modules/nixos/virtualisation.nix` |
