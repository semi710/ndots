# Beszel agent — lightweight monitoring agent for the Beszel hub.
# Import this module to enable the agent. The host must supply TOKEN_FILE
# from sops (see hosts/nixos/<host>/). Set services.beszel.agent.user to
# the docker-group username to target the rootless socket; the module
# then runs the agent as that user. Enable linger separately if the
# rootless socket must exist at boot without a login session.
#
# For non-NixOS devices, run the Docker image:
#   docker run -d --network host --restart unless-stopped \
#     -v /var/run/docker.sock:/var/run/docker.sock:ro \
#     -e KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYwmNqGPWjYdAoVH2IM3tp/liL8sHNF4/kladhQUzSQ' \
#     -e HUB_URL='https://beszel.semi.sh' \
#     -e TOKEN='<from sops: secrets/server.yaml beszel.token>' \
#     henrygd/beszel-agent:latest
# KEY is public (encrypts metrics), TOKEN is secret (from sops).
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.beszel.agent;
  rootless = cfg.user != null;
in
{
  options.services.beszel.agent.user = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      User to run the agent as when targeting the rootless docker socket.
      Set to the docker-group username on hosts using rootless docker.
      Leave null to run as a DynamicUser against the system socket.
    '';
  };

  config = {
    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environment = {
        HUB_URL = "http://obox:3090";
        LISTEN = "45876";
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYwmNqGPWjYdAoVH2IM3tp/liL8sHNF4/kladhQUzSQ beszel-hub@obox";
        DOCKER_HOST =
          if rootless then "unix:///run/user/1000/docker.sock" else "unix:///var/run/docker.sock";
      };
    };

    users.groups.beszel-token = { };

    systemd.services.beszel-agent = lib.mkMerge [
      {
        serviceConfig.SupplementaryGroups = [ "beszel-token" ];
        serviceConfig.PrivateUsers = lib.mkForce false;
      }
      (lib.mkIf rootless {
        serviceConfig.DynamicUser = lib.mkForce false;
        serviceConfig.User = lib.mkForce cfg.user;
        serviceConfig.Group = lib.mkForce "beszel-token";
      })
    ];
  };
}
