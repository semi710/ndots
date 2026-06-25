# semi - Semi-Personal

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i9-14900K (24c/32t) |
| **RAM** | 128 GB |
| **User** | nikhil.singh |
| **Role** | Semi-personal workstation (also a nix remote builder) |

## Services

- **FileBrowser Quantum** - serves `/` + user home
- **Beszel agent** - system + rootless Docker
- **Tailscale** - mesh VPN
- **Docker** - system + rootless

## Modules Imported

```nix
imports = [
  ../common/workstation.nix        # shared Juspay workstation config
  ./disk.nix
  ./hardware.nix
  ./extra-users.nix
];
```

The `common/workstation.nix` base imports: [default](../modules/nixos.md#basenix-defaultnix), [juspay](../modules/nixos.md#juspay), sops, disko, [beszel](../modules/nixos.md#beszelnix), [tailscale](../modules/nixos.md#tailscalenix), [virtualisation](../modules/nixos.md#virtualisationnix), [filebrowser](../modules/nixos.md#filebrowsernix).

## Nix Remote Builder

semi acts as a remote build host for dsd (and vice versa). Builder config is in `config.nix`:

```nix
builders.semi = {
  hostName = "semi";
  hostNames = [ "semi" "semi.persian-vega.ts.net" ];
  hostPublicKey = "ssh-ed25519 AAAA...";
};
```

Known hosts are wired via `programs.ssh.knownHosts` in `workstation.nix`. jp-mbp uses semi (and dsd) as remote build machines.

## Secrets

Uses `secrets/office.yaml` (office age key):

- `tailscale_auth_key`
- `beszel/token`
- `filebrowser/semi`
- `private-keys/nix_access_token`

## Files

- `hosts/nixos/semi/default.nix` - main config
- `hosts/nixos/semi/disk.nix` - disko partitioning
- `hosts/nixos/semi/hardware.nix` - auto-generated
- `hosts/nixos/semi/extra-users.nix` - additional users
