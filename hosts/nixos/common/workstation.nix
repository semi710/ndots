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
  ];

  sops.secrets."private-keys/beszel_u_token" = {
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE =
    config.sops.secrets."private-keys/beszel_u_token".path;

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
  };

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
