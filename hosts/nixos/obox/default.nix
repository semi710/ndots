# Beszel hub on Oracle Cloud (obox).
# Server config — hub + shell + SSH + networking + tailscale + sops + docker.
{
  flake,
  modulesPath,
  pkgs,
  lib,
  config,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me;
  username = "nikhil";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    flake.inputs.disko.nixosModules.disko
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.nix-index-database.nixosModules.nix-index
    ./disk.nix
    ./hardware.nix
    flake.flakeModules.nix
    flake.nixosModules.tailscale

    # Shorthand: config.hm.* → config.home-manager.users.${username}.*
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" username ])
  ];

  home-manager.sharedModules = [ { home.stateVersion = "26.05"; } ];
  home-manager.backupFileExtension = "backup";

  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 3090;
  };

  virtualisation.docker.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  environment.variables.TERM = "xterm-256color";

  networking.firewall.allowedTCPPorts = [ 3090 ];

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
    secrets."tailscale_auth_key" = { };
  };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = me.sshPublicKeys;
    shell = pkgs.zsh;
  };
  users.users.root.openssh.authorizedKeys.keys = me.sshPublicKeys;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
