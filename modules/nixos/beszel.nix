# Beszel agent — lightweight monitoring agent for the Beszel hub.
# Import this module to enable the agent. The host must supply TOKEN_FILE
# from sops (see hosts/nixos/<host>/default.nix).
{ ... }:
{
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      # Hub runs on Oracle cloud, exposed via Tailscale as "obox"
      HUB_URL = "http://obox:3090";
      LISTEN = "45876";
      # Public SSH key — hub holds the private half, SSHes into agent on 45876.
      # Required by the binary to start (loadPublicKeys runs unconditionally).
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKXiTYE4QsAduGVDIT2DBWPif8hpqxyr9I10eODCbqT";
    };
  };

  # beszel-agent uses DynamicUser (UID rotates per boot), so the sops
  # secret can't be owner=beszel-agent. We grant read via a fixed group.
  users.groups.beszel-token = { };
  systemd.services.beszel-agent.serviceConfig.SupplementaryGroups = [ "beszel-token" ];
}
