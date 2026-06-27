# mach - Personal Laptop

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i7-10510U (4c/8t) |
| **RAM** | 24 GB |
| **User** | niksingh710 |
| **Boot** | systemd-boot (UEFI) |
| **Timezone** | Asia/Kolkata |

## Services

- **FileBrowser Quantum** - serves `/run/media/niksingh710/` (external media) + user home
- **Beszel agent** - monitors system + rootless Docker (runs as user, SKIP_GPU=true)
- **Tailscale** - mesh VPN
- **Docker** - system + rootless via shared [virtualisation](../modules/nixos.md#virtualisationnix) module

## Modules Imported

```nix
imports = [
  flake.nixosModules.default       # base system
  flake.nixosModules.hardware      # audio, bluetooth, touchpad
  flake.nixosModules.filebrowser
  flake.nixosModules.beszel
  flake.nixosModules.tailscale
  flake.nixosModules.virtualisation
  flake.inputs.sops-nix.nixosModules.sops
  flake.inputs.disko.nixosModules.disko
  # Hyprland is commented out (CLI-based machine)
];
```

## Notable Config

```nix
# AMD GPU bug workaround - beszel crashes reading sysfs
# https://github.com/henrygd/beszel/issues/1799
services.beszel.agent.environment.SKIP_GPU = "true";

# Rootless docker agent - runs as user to access /run/user/1000/docker.sock
services.beszel.agent.environment.DOCKER_HOST = "unix:///run/user/1000/docker.sock";

# FileBrowser includes external media mount
services.filebrowser-quantum = {
  enable = true;
  sources = [ "/run/media/niksingh710/" ];
  home = "/home/niksingh710";
};

# Auto-login on TTY (CLI machine)
services.getty.autologinUser = "niksingh710";
```

## Secrets

System level uses `secrets/server.yaml` (office age key):

- `tailscale_auth_key`
- `beszel/token`
- `filebrowser/mach`
- `user-password`

Home level uses `secrets/keys.yaml` (personal age key):

- `tokens/ai/gemini`, `tokens/ai/openai`, `tokens/ai/openrouter`, `tokens/ai/opencode-zen`
- `tokens/github`, `tokens/cachix`, `tokens/nix-access`
- `ssh/private`
- `rclone/conf`, `rclone/locked-conf`
- `syncthing/mach/{password,cert,key}`

Home level also pulls from `secrets/office.yaml`:

- `private-keys/jp-key` (Juspay API key)

And from `secrets/server.yaml`:

- `naste/user`, `naste/pass`

## Files

- `hosts/nixos/mach/default.nix` - main config
- `hosts/nixos/mach/disk.nix` - disko partitioning
- `hosts/nixos/mach/hardware.nix` - auto-generated hardware config
