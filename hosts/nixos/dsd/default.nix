{ ... }:
{
  imports = [
    ../common/workstation.nix
    ./disk.nix
    ./hardware.nix
    ./extra-users.nix
    # flake.nixosModules.minecraft
  ];
}
