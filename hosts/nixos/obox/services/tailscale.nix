# Tailscale auth key wiring for obox.
{
  config,
  ...
}:
{
  sops.secrets."tailscale_auth_key" = { };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
}
