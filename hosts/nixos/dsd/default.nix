{
  flake,
  lib,
  pkgs,
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
    flake.nixosModules.office
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    ./hardware.nix
    ./extra-users.nix
  ];

  environment.variables = {
    TERM = "xterm-256color";
    ZSH_DISABLE_COMPFIX = "true";
  };
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    groups.extra = { };
    users.${me.username} = {
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
  };

  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    extraConfig = "AcceptEnv LANG LC_* JUSPAY_API_KEY ANTHROPIC_* GITHUB_* CLAUDE_*";
  };

  # Known hosts for remote builds (e.g. nxbuild semi .#foo or nix build --builders ssh://semi .#foo)
  programs.ssh.knownHosts = {
    semi = {
      inherit (cfg.builders.semi) hostNames;
      publicKey = cfg.builders.semi.hostPublicKey;
    };
  };

  sops = {
    age.keyFile = "${config.users.users.${me.username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/office.yaml";
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  networking = {
    stevenblack.enable = true;
    networkmanager.enable = true;
  };
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ me.username ];

  hm.sops.secrets."private-keys/nix_access_token" = {
    sopsFile = "${flake}/secrets/office.yaml";
  };
  nix.extraOptions = "!include ${config.hm.sops.secrets."private-keys/nix_access_token".path}";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
