# naste - self-hosted paste service (Caddy-proxied, Tailscale-only).
{
  flake,
  config,
  ...
}:
{
  imports = [ flake.inputs.naste.nixosModules.default ];

  services.naste-server = {
    enable = true;
    port = 8080;
    openFirewall = false;
  };

  sops.secrets."naste/user" = {
    group = "naste";
    mode = "0440";
  };
  sops.secrets."naste/pass" = {
    group = "naste";
    mode = "0440";
  };
  services.naste-server.private.userFile = config.sops.secrets."naste/user".path;
  services.naste-server.private.passFile = config.sops.secrets."naste/pass".path;
}
