# Beszel hub on Oracle Cloud (obox).
# Server config — hub + shell + SSH + networking + tailscale + sops + docker.
# Service configs live in ./services/.
{
  flake,
  modulesPath,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = import (flake + "/config.nix");
  me = cfg.users.me;
  username = cfg.users.obox.username;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    flake.inputs.disko.nixosModules.disko
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.nix-index-database.nixosModules.nix-index
    flake.flakeModules.nix
    flake.nixosModules.tailscale
    flake.nixosModules.beszel
    flake.nixosModules.virtualisation
    flake.nixosModules.filebrowser

    # Shorthand: config.hm.* → config.home-manager.users.${username}.*
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" username ])
  ]
  ++ flake.inputs.nix-wire.lib.autoImport ./.;

  home-manager.sharedModules = [
    { home.stateVersion = "26.05"; }
    flake.homeModules.naste
  ];
  home-manager.backupFileExtension = "backup";

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  environment.variables.TERM = "xterm-256color";

  networking.firewall.allowedTCPPorts = [
    80
    443
    3090
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/server.yaml";
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = me.sshPublicKeys;
    shell = pkgs.zsh;
  };
  users.users.root.openssh.authorizedKeys.keys = me.sshPublicKeys;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
