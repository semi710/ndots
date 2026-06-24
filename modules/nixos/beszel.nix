# Beszel agent — lightweight monitoring agent for the Beszel hub.
# Import this module to enable the agent. The host must supply TOKEN_FILE
# from sops (see hosts/nixos/<host>/default.nix).
# For rootless docker, the host must also override DOCKER_HOST and User
# (see hosts/nixos/common/workstation.nix for an example).
{
  lib,
  ...
}:
{
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environment = {
      HUB_URL = "http://obox:3090";
      LISTEN = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYwmNqGPWjYdAoVH2IM3tp/liL8sHNF4/kladhQUzSQ beszel-hub@obox";
      DOCKER_HOST = "unix:///var/run/docker.sock";
    };
  };

  users.groups.beszel-token = { };
  systemd.services.beszel-agent = {
    serviceConfig.SupplementaryGroups = [ "beszel-token" ];
    serviceConfig.PrivateUsers = lib.mkForce false;
  };
}
