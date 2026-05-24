{
  flake,
  modulesPath,
  pkgs,
  lib,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.virt;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    ./hardware.nix

    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.flakeModules.nix
  ];

  home-manager.sharedModules = [
    flake.homeModules.default
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];
  users.users.root.openssh.authorizedKeys.keys = me.sshPublicKeys;
  users.users.${me.username} = {
    name = me.username;
    isNormalUser = true;
    openssh.authorizedKeys.keys = me.sshPublicKeys;
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
  # according to the platform
  nixpkgs.hostPlatform = "aarch64-linux";
}
