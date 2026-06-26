# Caddy reverse proxy — imperative config at /etc/caddy/Caddyfile, reload on change.
{ ... }:
{
  services.caddy = {
    enable = true;
    configFile = "/etc/caddy/Caddyfile";
    enableReload = true;
  };
}
