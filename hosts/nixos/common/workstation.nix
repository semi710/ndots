# Shared workstation configuration for Juspay work machines (dsd, semi)
{
  flake,
  lib,
  config,
  ...
}:
let
  cfg = import (flake + "/config.nix");
  me = cfg.users.me // {
    username = "nikhil.singh";
  };
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.nixosModules.default
    flake.nixosModules.juspay
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.disko.nixosModules.disko
    flake.nixosModules.beszel
    flake.nixosModules.tailscale
  ];

  sops.secrets."beszel/token" = {
    sopsFile = "${flake}/secrets/server.yaml";
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
  # Rootless docker socket is per-user at /run/user/<uid>/docker.sock.
  # The agent must run as that user to traverse the 0700 directory.
  services.beszel.agent.environment.DOCKER_HOST = lib.mkForce "unix:///run/user/1000/docker.sock";
  systemd.services.beszel-agent = {
    serviceConfig.DynamicUser = lib.mkForce false;
    serviceConfig.User = lib.mkForce me.username;
    serviceConfig.Group = lib.mkForce "beszel-token";
  };

  users.users.${me.username} = {
    name = me.username;
    home = "/home/${me.username}";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "extra"
      "docker"
    ];
    openssh.authorizedKeys.keys = me.sshPublicKeys ++ [ cfg.builders.key.publicKey ];
  };
  users.groups.extra = { };

  nix.settings.trusted-users = [ me.username ];

  sops = {
    age.keyFile = "${config.users.users.${me.username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/office.yaml";
    secrets."tailscale_auth_key" = { };
  };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;

  hm.sops.secrets."private-keys/nix_access_token" = {
    sopsFile = "${flake}/secrets/office.yaml";
  };
  nix.extraOptions = "!include ${config.hm.sops.secrets."private-keys/nix_access_token".path}";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  # Known hosts for remote builds — both workstations know about each other
  programs.ssh.knownHosts = {
    dsd = {
      inherit (cfg.builders.dsd) hostNames;
      publicKey = cfg.builders.dsd.hostPublicKey;
    };
    semi = {
      inherit (cfg.builders.semi) hostNames;
      publicKey = cfg.builders.semi.hostPublicKey;
    };
  };
}
