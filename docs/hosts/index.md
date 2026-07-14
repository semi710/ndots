# Hosts

All NixOS hosts are managed declaratively via flakes. Each host has its own directory under `hosts/nixos/`. Darwin hosts live under `hosts/darwin/`. Standalone home-manager configs live under `hosts/home/`.

## NixOS Hosts

| Host | Arch | CPU | RAM | Disk | User | Key Services |
|------|------|-----|-----|------|------|---------------|
| [mach](mach.md) | x86_64 | Intel i7-10510U (4c/8t) | 24 GB | NVMe | niksingh710 | FileBrowser, Beszel agent, Docker |
| [dsd](dsd.md) | x86_64 | Intel i9-12900KS (16c/24t) | 64 GB | NVMe | nikhil.singh | FileBrowser, Beszel agent, Docker, Minecraft |
| [semi](semi.md) | x86_64 | Intel i9-14900K (24c/32t) | 128 GB | NVMe | nikhil.singh | FileBrowser, Beszel agent, Docker |
| [obox](obox.md) | aarch64 | Ampere Neoverse-N1 (4c/4t) | 24 GB | 200G | nikhil | Beszel hub, Stirling PDF, FileBrowser, Caddy, naste |
| [bbox](bbox.md) | aarch64 | Ampere Neoverse-N1 (4c/4t) | 24 GB | 200G | nikhil | Beszel hub, Caddy |
| [jp-mbp](jp-mbp.md) | aarch64 | Apple M4 | - | - | nikhil.singh | Yabai, Aerospace, Karabiner |

## Darwin Hosts

| Host | Arch | Role |
|------|------|------|
| [jp-mbp](jp-mbp.md) | aarch64 | MacBook Pro M4 |

## Templates

| Host | Purpose |
|------|---------|
| [anywhere](anywhere.md) | Generic NixOS server template for nixos-anywhere |
| virt-x86_64 | VM testing (x86_64) |
| virt-aarch64 | VM testing (aarch64) |

## Standalone Home Configs

| Config | User | Modules |
|---|---|---|
| `hosts/home/nikhil.nix` | nikhil | default, ai, stylix (cli-only), git with Juspay conditional email |
| `hosts/home/admin.nix` | (current) | default, home-only |

## Common Config

Workstations (semi, dsd) share `hosts/nixos/common/workstation.nix` which imports:

- [base](../modules/nixos.md#basenix-defaultnix) (`nixosModules.default`)
- [juspay](../modules/nixos.md#juspay) (`nixosModules.juspay`) - workspace config (zsh, openssh, docker, tailscale, postgres, redis)
- sops-nix for secrets
- disko for disk management
- [Beszel](../modules/nixos.md#beszelnix) agent
- [Tailscale](../modules/nixos.md#tailscalenix)
- [Virtualisation](../modules/nixos.md#virtualisationnix) (docker + podman)
- [FileBrowser Quantum](../modules/nixos.md#filebrowsernix)

It also wires:

- The `nikhil.singh` user (from `config.nix`, Juspay identity) with wheel/docker/networkmanager groups
- sops age key at `~/.config/sops/age/keys.txt`, default file `secrets/office.yaml`
- Tailscale auth key from sops
- Beszel agent as user (rootless Docker) with token from sops
- FileBrowser password from sops
- nix access token from sops (via `!include` in `nix.extraOptions`)
- SSH known hosts for dsd + semi (cross-building)

Cloud servers (obox, bbox) share `hosts/nixos/common/cloud.nix` which imports:

- `flakeModules.nix` directly for Nix settings, not `nixosModules.default`
- sops-nix for `secrets/server.yaml`
- disko for disk management
- [Beszel](../modules/nixos.md#beszelnix) hub and self-monitoring agent
- [Tailscale](../modules/nixos.md#tailscalenix)
- [Virtualisation](../modules/nixos.md#virtualisationnix) (docker + podman)
- Caddy

It also wires:

- The per-host user from `config.nix` with wheel/docker groups
- sops age key at `~/.config/sops/age/keys.txt`, default file `secrets/server.yaml`
- Tailscale auth key from sops
- Beszel hub credentials and agent token from sops
Each host then overrides or extends as needed (e.g., mach adds media mount, obox adds FileBrowser, Stirling PDF and naste-server, obox/bbox provide disk and hardware files, dsd adds minecraft).

## Host Inheritance Summary

| Host | Base | Extra imports |
|------|------|---------------|
| semi | `common/workstation.nix` | disk, hardware, extra-users |
| dsd | `common/workstation.nix` | disk, hardware, extra-users, minecraft |
| mach | (standalone) | default, hardware, filebrowser, beszel, tailscale, virtualisation, sops, disko |
| obox | `common/cloud.nix` | disk, hardware, user |
| bbox | `common/cloud.nix` | disk, hardware, user |
| jp-mbp | `darwinModules.default` | yabai, sops |
| anywhere | (template) | nix, disko, qemu-guest |
| virt-* | `nixosModules.default` | disko, hardware |
