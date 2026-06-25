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
- **Docker** - system only (for OCI containers)

## Modules Imported

```nix
imports = [
  flake.flakeModules.nix            # nix settings
  flake.nixosModules.tailscale
  flake.nixosModules.beszel
  flake.nixosModules.virtualisation
  flake.nixosModules.filebrowser
  flake.inputs.sops-nix.nixosModules.sops
  flake.inputs.disko.nixosModules.disko
  flake.inputs.nix-index-database.nixosModules.nix-index
];
```

!!! note "No base module"
    obox does **not** import `nixosModules.default` - it's a server, so it skips stylix, home-manager default modules, and the cachyos kernel overlay. It imports `flakeModules.nix` directly for nix settings.

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
- `filebrowser/obox`

## Files

- `hosts/nixos/obox/default.nix` - main config
- `hosts/nixos/obox/disk.nix` - disko partitioning
- `hosts/nixos/obox/hardware.nix` - QEMU guest hardware
