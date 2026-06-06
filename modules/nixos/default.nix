{ flake, pkgs, ... }:
let
  inherit (flake.inputs) nix-cachyos-kernel;
in
{
  imports = [
    flake.flakeModules.nix
    flake.nixosModules.stylix
  ];

  home-manager.sharedModules = [
    flake.homeModules.default
  ];

  # Backup conflicting home files instead of failing activation
  home-manager.backupFileExtension = "backup";

  programs.nix-ld.enable = true;
  services.envfs.enable = true;
  environment.systemPackages = with pkgs; [
    # ensuring some packages to be available for every user
    bash
    coreutils
    curl
    wget
    git
    gnutar
    gzip
    xz
    xdg-utils
    openssh
  ];

  nixpkgs.overlays = [
    nix-cachyos-kernel.overlays.pinned
  ];
}
