# Deploy tooling shared by every NixOS host. Imported by both
# cloud.nix and nixosModules.default so `nh os switch` remote diffs
# work everywhere without duplicating the package list.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.dix ];
}
