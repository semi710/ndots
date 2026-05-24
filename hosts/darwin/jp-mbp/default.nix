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
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" config.system.primaryUser ])
    flake.darwinModules.default
    flake.darwinModules.yabai
    flake.inputs.sops-nix.darwinModules.sops
  ];

  users.users.${me.username} = {
    name = me.username;
    home = "/Users/${me.username}";
    openssh.authorizedKeys.keys = me.sshPublicKeys;
  };

  # Remote builders (client-only)
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
  sops = {
    age.keyFile = "${config.users.users.${me.username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/office.yaml";
    secrets."private-keys/nix-builder" = {
      owner = me.username;
      group = "staff";
      mode = "0600";
      path = "${config.users.users.${me.username}.home}/.ssh/nix-builder";
    };
  };
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      inherit (cfg.builders.dsd)
        hostName
        system
        maxJobs
        speedFactor
        supportedFeatures
        sshUser
        ;
      mandatoryFeatures = [ ];
      sshKey = config.sops.secrets."private-keys/nix-builder".path;
    }
    {
      inherit (cfg.builders.semi)
        hostName
        system
        maxJobs
        speedFactor
        supportedFeatures
        sshUser
        ;
      mandatoryFeatures = [ ];
      sshKey = config.sops.secrets."private-keys/nix-builder".path;
    }
  ];

  hm.sops.secrets."private-keys/nix_access_token" = { };
  nix.extraOptions = "!include ${config.hm.sops.secrets."private-keys/nix_access_token".path}";

  environment.etc."sudoers.d/10-nix-sudo".text = "${me.username} ALL=(ALL:ALL) NOPASSWD: ALL";
  system.primaryUser = me.username;
  nix.settings.trusted-users = [ me.username ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
