# dsd — Work Desktop

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i9-12900KS (16c/24t) |
| **RAM** | 64 GB |
| **User** | nikhil.singh |
| **Role** | Juspay work desktop (also a nix remote builder) |

## Services

- **FileBrowser Quantum** — serves `/` + `/home` (all users) + user home
- **Beszel agent** — system + rootless Docker
- **Tailscale** — mesh VPN
- **Docker** — system + rootless
- **Minecraft** — Paper server with plugins (via [nix-minecraft](../modules/nixos.md#minecraft))

## Modules Imported

```nix
imports = [
  ../common/workstation.nix        # shared Juspay workstation config
  ./disk.nix
  ./hardware.nix
  ./extra-users.nix
  flake.nixosModules.minecraft     # Minecraft server
];
```

The `common/workstation.nix` base imports: [default](../modules/nixos.md#basenix-defaultnix), [juspay](../modules/nixos.md#juspay), sops, disko, [beszel](../modules/nixos.md#beszelnix), [tailscale](../modules/nixos.md#tailscalenix), [virtualisation](../modules/nixos.md#virtualisationnix), [filebrowser](../modules/nixos.md#filebrowsernix).

## Notable Config

```nix
# FileBrowser serves root + all user homes
services.filebrowser-quantum.sources = [ "/" "/home" ];
```

## Minecraft Server

Runs a Paper server named `dsd` (see [minecraft module](../modules/nixos.md#minecraft)):

- Port 25565, survival, normal difficulty, 20 max players
- Offline mode, whitelist enabled (semi710, LightX017, fiery518)
- Plugins: SimpleTPA, ViaVersion, ViaBackwards, DeathChest, ServerHomes, SimpleVoiceChat
- Voice chat UDP port 24454

## Nix Remote Builder

dsd acts as a remote build host for semi (and vice versa). Builder config is in `config.nix`:

```nix
builders.dsd = {
  hostName = "dsd";
  hostNames = [ "dsd" "dsd.persian-vega.ts.net" ];
  hostPublicKey = "ssh-ed25519 AAAA...";
};
```

Known hosts are wired via `programs.ssh.knownHosts` in `workstation.nix`.

## Files

- `hosts/nixos/dsd/default.nix` — main config
- `hosts/nixos/dsd/disk.nix` — disko partitioning
- `hosts/nixos/dsd/hardware.nix` — auto-generated
- `hosts/nixos/dsd/extra-users.nix` — additional Juspay users
