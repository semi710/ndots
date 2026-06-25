# obox — Oracle Cloud VPS

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

This is the hub host — runs central services for the network.

- **Beszel hub** — monitoring dashboard, agents from all hosts connect here
- **Stirling PDF** — self-hosted PDF tools, branded "semi.sh PDF"
- **FileBrowser Quantum** — serves `/` + user home
- **Caddy** — reverse proxy (imperative config, no rebuild needed)
- **Tailscale** — mesh VPN
- **Docker** — system only (for OCI containers)

## Beszel Hub Setup

The hub SSH key is copied to PocketBase's data dir on startup via `preStart`:

```nix
systemd.services.beszel-hub.preStart = ''
  cp "${config.sops.secrets."beszel/ssh_key".path}" \
     /var/lib/beszel-hub/beszel_data/id_ed25519
  chmod 0600 /var/lib/beszel-hub/beszel_data/id_ed25519
'';
```

Universal token enrollment (one-time, after fresh DB):

```bash
# Get JWT
JWT=$(curl -s http://localhost:<port>/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"<email>","password":"<pass>"}' | jq -r .token)

# Enable universal token
curl "http://localhost:<port>/api/beszel/universal-token?enable=1&permanent=1&token=<token>" \
  -H "Authorization: $JWT"
```

## Caddy

Imperative config at `/etc/caddy/Caddyfile` — edit directly on the box, `systemctl reload caddy`. No rebuild needed.

## Firewall

```nix
networking.firewall.allowedTCPPorts = [ 80 443 ]; # Caddy
# Beszel hub + FileBrowser are Tailscale-only (not opened publicly)
```

## Files

- `hosts/nixos/obox/default.nix` — main config
- `hosts/nixos/obox/disk.nix` — disko partitioning
- `hosts/nixos/obox/hardware.nix` — QEMU guest hardware
