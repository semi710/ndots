# obox - Oracle Cloud VPS

| | |
|---|---|
| **Platform** | NixOS aarch64 |
| **CPU** | Ampere Neoverse-N1 (4c/4t) |
| **RAM** | 24 GB |
| **Disk** | 200 GB (`/dev/sda`) |
| **User** | nikhil |
| **Public IP** | `140.245.237.190` |
| **Boot** | GRUB (EFI removable) |

## Services

This is the **hub host** - runs central services for the network.

- **[Beszel hub](../services/beszel.md)** - monitoring dashboard, agents from all hosts connect here
- **[Stirling PDF](../services/stirling-pdf.md)** - self-hosted PDF tools, branded "semi.sh PDF"
- **[FileBrowser Quantum](../services/filebrowser.md)** - serves `/` + user home
- **[Caddy](../services/caddy.md)** - reverse proxy (imperative config, no rebuild needed)
- **[Tailscale](../services/tailscale.md)** - mesh VPN
- **naste** - self-hosted paste service
- **Docker** - system only (for OCI containers)

## Modules Imported

```nix
imports = [
  (import ../common/cloud.nix { hostName = "obox"; })
]
++ flake.inputs.nix-wire.lib.autoImport ./.;
```

!!! note "No base module"
    `common/cloud.nix` does **not** import `nixosModules.default` - these are servers, so they skip stylix, home-manager default modules, and the cachyos kernel overlay. It imports `flakeModules.nix` directly for Nix settings.

## Beszel Hub Setup

The hub SSH key is copied to PocketBase's data dir on startup via `preStart`:

```nix
systemd.services.beszel-hub.preStart = ''
  cp "${config.sops.secrets."beszel/ssh_key".path}" \
     /var/lib/beszel-hub/beszel_data/id_ed25519
  chmod 0600 /var/lib/beszel-hub/beszel_data/id_ed25519
'';
```

Hub credentials composed via sops template:

```nix
sops.templates."beszel-hub-env" = {
  content = ''
    USER_EMAIL=${config.sops.placeholder."beszel/username"}
    USER_PASSWORD=${config.sops.placeholder."beszel/password"}
  '';
};
```

Universal token enrollment (one-time, after fresh DB):

```bash
# Get JWT
JWT=$(curl -s http://localhost:3090/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"<email>","password":"<pass>"}' | jq -r .token)

# Enable universal token
curl "http://localhost:3090/api/beszel/universal-token?enable=1&permanent=1&token=<token>" \
  -H "Authorization: $JWT"
```

## Caddy

Imperative config at `/etc/caddy/Caddyfile` - edit directly on the box, `systemctl reload caddy`. No rebuild needed.

## Firewall

```nix
networking.firewall.allowedTCPPorts = [ 80 443 3090 ];
# 80/443 = Caddy, 3090 = Beszel hub
# FileBrowser is Tailscale-only (not opened publicly)
```

## Secrets

Uses `secrets/server.yaml` (office age key):

- `tailscale_auth_key`
- `beszel/token` (agent), `beszel/ssh_key`, `beszel/username`, `beszel/password` (hub)
- `naste/user`, `naste/pass`
- `filebrowser/obox`

## Files

- `hosts/nixos/common/cloud.nix` - shared cloud server config and services
- `hosts/nixos/obox/default.nix` - host entrypoint
- `hosts/nixos/obox/filebrowser.nix` - FileBrowser Quantum service
- `hosts/nixos/obox/naste.nix` - naste server
- `hosts/nixos/obox/stirling-pdf.nix` - Stirling PDF service
- `hosts/nixos/obox/disk.nix` - disko partitioning
- `hosts/nixos/obox/hardware.nix` - QEMU guest hardware
- `hosts/nixos/obox/users/nikhil.nix` - home-manager imports
