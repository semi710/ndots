# Caddy

[Caddy](https://caddyserver.com/) reverse proxy on obox. Automatic HTTPS via Let's Encrypt.

## Configuration

Imperative - the Caddyfile is at `/etc/caddy/Caddyfile` and can be edited directly on the box without a NixOS rebuild.

```nix
services.caddy = {
  enable = true;
  configFile = "/etc/caddy/Caddyfile";
  enableReload = true;
};
```

## Managing Routes

```bash
# Edit the Caddyfile
sudo nano /etc/caddy/Caddyfile

# Validate config
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload (no restart needed)
sudo systemctl reload caddy
```

## Adding a New Route

Append to the Caddyfile:

```caddy
subdomain.semi.sh {
    reverse_proxy localhost:<port>
}
```

Caddy handles TLS automatically. WebSocket support is built-in - no extra config needed.

## Firewall

Ports 80 and 443 are opened in the NixOS firewall:

```nix
networking.firewall.allowedTCPPorts = [ 80 443 ];
```
