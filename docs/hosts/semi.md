# semi — Semi-Personal

| | |
|---|---|
| **Platform** | NixOS x86_64 |
| **CPU** | Intel i9-14900K (24c/32t) |
| **RAM** | 128 GB |
| **User** | nikhil.singh |
| **Role** | Semi-personal workstation (also a nix remote builder) |

## Services

- **FileBrowser Quantum** — serves `/` + user home
- **Beszel agent** — system + rootless Docker
- **Tailscale** — mesh VPN
- **Docker** — system + rootless

## Nix Remote Builder

semi acts as a remote build host for dsd (and vice versa). Builder config is in `config.nix`:

```nix
builders.semi = {
  hostName = "semi";
  hostNames = [ "semi" "semi.persian-vega.ts.net" ];
  hostPublicKey = "ssh-ed25519 AAAA...";
};
```

Known hosts are wired via `programs.ssh.knownHosts` in `workstation.nix`.

## Inheritance

Shares `common/workstation.nix` with dsd. Minimal host-specific config:

```nix
imports = [
  ../common/workstation.nix
  ./disk.nix
  ./hardware.nix
  ./extra-users.nix
];
```

## Files

- `hosts/nixos/semi/default.nix` — main config
- `hosts/nixos/semi/disk.nix` — disko partitioning
- `hosts/nixos/semi/hardware.nix` — auto-generated
- `hosts/nixos/semi/extra-users.nix` — additional users
