# dsd — Work Desktop

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i9-12900KS (16c/24t) |
| **RAM** | 64 GB |
| **User** | nikhil.singh |
| **Role** | Juspay work desktop |

## Services

- **FileBrowser Quantum** — serves `/` + `/home` (all users) + user home
- **Beszel agent** — system + rootless Docker
- **Tailscale** — mesh VPN
- **Docker** — system + rootless
- **Minecraft** — nix-minecraft module

## Inheritance

Shares `common/workstation.nix` with semi. Extra imports:

```nix
imports = [
  ../common/workstation.nix
  ./disk.nix
  ./hardware.nix
  ./extra-users.nix
  flake.nixosModules.minecraft
];
```

## Files

- `hosts/nixos/dsd/default.nix` — main config
- `hosts/nixos/dsd/disk.nix` — disko partitioning
- `hosts/nixos/dsd/hardware.nix` — auto-generated
- `hosts/nixos/dsd/extra-users.nix` — additional Juspay users
