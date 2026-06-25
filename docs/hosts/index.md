# Hosts

All NixOS hosts are managed declaratively via flakes. Each host has its own directory under `hosts/nixos/`. Darwin hosts live under `hosts/darwin/`.

## NixOS Hosts

| Host | Arch | CPU | RAM | Disk | User | Key Services |
|------|------|-----|-----|------|------|---------------|
| [mach](mach.md) | x86_64 | Intel i7-10510U (4c/8t) | 24 GB | NVMe | niksingh710 | FileBrowser, Beszel agent, Docker |
| [dsd](dsd.md) | x86_64 | Intel i9-12900KS (16c/24t) | 64 GB | NVMe | nikhil.singh | FileBrowser, Beszel agent, Docker |
| [semi](semi.md) | x86_64 | Intel i9-14900K (24c/32t) | 128 GB | NVMe | nikhil.singh | FileBrowser, Beszel agent, Docker |
| [obox](obox.md) | aarch64 | Ampere Neoverse-N1 (4c/4t) | 24 GB | 200G | nikhil | Beszel hub, Stirling PDF, FileBrowser, Caddy |
| [jp-mbp](jp-mbp.md) | aarch64 | Apple M4 | — | — | nikhil.singh | Yabai, Aerospace, Karabiner |

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

## Common Config

Workstations (semi, dsd) share `hosts/nixos/common/workstation.nix` which imports:

- Base NixOS modules (default, juspay)
- sops-nix for secrets
- disko for disk management
- Beszel agent
- Tailscale
- Virtualisation (docker + podman)
- FileBrowser Quantum

Each host then overrides or extends as needed (e.g., mach adds media mount, obox adds hub services).
