# Tailscale

[Tailscale](https://tailscale.com/) mesh VPN connects all hosts. Each host authenticates with an auth key from sops.

## Module

`modules/nixos/tailscale.nix` - just enables the service:

```nix
{ ... }: {
  services.tailscale.enable = true;
}
```

Hosts wire the auth key from sops:

```nix
sops.secrets."tailscale_auth_key" = { };
services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
```

## Tailnet

All hosts are on the `persian-vega.ts.net` tailnet. Hosts are reachable via:

- `<hostname>` (MagicDNS)
- `<hostname>.persian-vega.ts.net` (FQDN)

## Firewall

Tailscale sets `checkReversePath = "loose"` automatically. Services that should be Tailscale-only trust the `tailscale0` interface:

```nix
networking.firewall.trustedInterfaces = [ "tailscale0" ];
```

This opens the port on Tailscale but not on the public interface.

## Auth Keys

Stored in sops:

- `secrets/office.yaml` → `tailscale_auth_key` (for semi, dsd)
- `secrets/server.yaml` → `tailscale_auth_key` (for obox, mach)
