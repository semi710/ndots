# Shared Tailscale module — just enables the service.
# Hosts wire the auth key:
#   sops.secrets."tailscale_auth_key" = { };
#   services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
{ ... }:
{
  services.tailscale.enable = true;
}
