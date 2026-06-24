# Generic NixOS server template. Copy this directory, rename it,
# and adjust the values below. Deploy with nixos-anywhere:
#
#   nix run github:nix-community/nixos-anywhere -- \
#     --generate-hardware-config nixos-generate-config ./hosts/nixos/<name>/hardware.nix \
#     --flake .#<name> \
#     --target-host root@<ip>
#
# This template is intentionally bare — no services, no sops, no
# home-manager. Add what you need per-host.
{
  flake,
  modulesPath,
  pkgs,
  lib,
  ...
}:
let
  # Uses the "virt" user from config.nix. Override or replace with
  # a real user for production hosts.
  me = (import (flake + "/config.nix")).users.virt;
in
{
  imports = [
    # Auto-detect hardware at install time via --generate-hardware-config
    (modulesPath + "/installer/scan/not-detected.nix")
    # QEMU/KVM guest — sets virtio kernel modules. Swap for
    # profiles/qemu-guest, profiles/hcloud-guest, etc. as needed.
    (modulesPath + "/profiles/qemu-guest.nix")

    # Declarative disk partitioning
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    ./hardware.nix # ← auto-generated, don't edit by hand

    # Nix settings (latest nix, gc, registry, caches)
    flake.flakeModules.nix
  ];

  # Grub with EFI. disko adds EF02 partition devices automatically.
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # NetworkManager — works on most platforms. For cloud VMs that
  # drop connectivity on reboot, switch to systemd-networkd:
  #
  #   networking.useNetworkd = true;
  #   systemd.network = {
  #     enable = true;
  #     networks."10-lan" = {
  #       matchConfig.Type = "ether";
  #       networkConfig.DHCP = "yes";
  #     };
  #   };
  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = me.sshPublicKeys;
  users.users.${me.username} = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = me.sshPublicKeys;
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux"; # ← set to match target arch
  system.stateVersion = "25.11";
}
