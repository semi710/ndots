# bbox - Oracle Cloud VPS

| | |
|---|---|
| **Platform** | NixOS aarch64 |
| **CPU** | Ampere Neoverse-N1 (4c/4t) |
| **RAM** | 24 GB |
| **Disk** | 200 GB (`/dev/sda`) |
| **User** | nikhil |
| **Boot** | GRUB (EFI removable) |

## Services

`bbox` uses the shared cloud server profile from `hosts/nixos/common/cloud.nix`:

- **[Beszel hub](../services/beszel.md)** - monitoring dashboard, agents from all hosts connect here
- **[Caddy](../services/caddy.md)** - reverse proxy (imperative config, no rebuild needed)
- **[Tailscale](../services/tailscale.md)** - mesh VPN
- **Docker** - system only (for OCI containers)

FileBrowser, Stirling PDF, and naste-server are intentionally not enabled on `bbox`; they stay on `obox`.

## Modules Imported

```nix
imports = [
  (import ../common/cloud.nix { hostName = "bbox"; })
]
++ flake.inputs.nix-wire.lib.autoImport ./.;
```

## Remote Install

`bbox` expects the sops age key at `/home/nikhil/.config/sops/age/keys.txt`. Stage it with `--extra-files` during the first install. The temp directory mirrors the target root because `--extra-files` copies its contents into `/`; `--chown` gives the copied key directory back to the final user so home-manager can write the rest of `~/.config`.

```bash
user=nikhil
ip=<ip>

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

keydir="$tmp/home/$user/.config/sops/age"
install -d -m 700 "$keydir"
install -m 600 "$HOME/.config/sops/age/keys.txt" "$keydir/keys.txt"

nix run github:nix-community/nixos-anywhere -- \
  --build-on remote \
  --option accept-flake-config true \
  --option download-buffer-size 536870912 \
  --extra-files "$tmp" \
  --chown "/home/$user/.config/sops/age" "$user:users" \
  --generate-hardware-config nixos-generate-config ./hosts/nixos/bbox/hardware.nix \
  --flake "path:$PWD#bbox" \
  --target-host "root@$ip"
```

If the target starts from an Ubuntu cloud image, `root` SSH must accept the same key as `ubuntu` before running `nixos-anywhere`. If SSH asks for a root password after install, check that the local shell still has the right `ssh-agent` key loaded.

## Secrets

Uses `secrets/server.yaml`:

- `tailscale_auth_key`
- `beszel/token` (agent), `beszel/ssh_key`, `beszel/username`, `beszel/password` (hub)

## Files

- `hosts/nixos/common/cloud.nix` - shared cloud server config and services
- `hosts/nixos/bbox/default.nix` - host entrypoint
- `hosts/nixos/bbox/disk.nix` - disko partitioning
- `hosts/nixos/bbox/hardware.nix` - QEMU guest hardware
- `hosts/nixos/bbox/users/nikhil.nix` - home-manager imports
