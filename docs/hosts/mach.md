# mach — Personal Laptop

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i7-10510U (4c/8t) |
| **RAM** | 24 GB |
| **User** | niksingh710 |
| **Boot** | systemd-boot (UEFI) |

## Services

- **FileBrowser Quantum** — serves `/run/media/niksingh710/` (external media) + user home
- **Beszel agent** — monitors system + rootless Docker (runs as user, SKIP_GPU=true)
- **Tailscale** — mesh VPN
- **Docker** — system + rootless via shared virtualisation module

## Notable Config

```nix
# AMD GPU bug workaround — beszel crashes reading sysfs
# https://github.com/henrygd/beszel/issues/1799
services.beszel.agent.environment.SKIP_GPU = "true";

# Rootless docker agent — runs as user to access /run/user/1000/docker.sock
services.beszel.agent.environment.DOCKER_HOST = "unix:///run/user/1000/docker.sock";
```

## Files

- `hosts/nixos/mach/default.nix` — main config
- `hosts/nixos/mach/disk.nix` — disko partitioning
- `hosts/nixos/mach/hardware.nix` — auto-generated hardware config
