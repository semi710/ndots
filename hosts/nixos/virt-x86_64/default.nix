{ flake, ... }:
{
  imports = [ ../virt-common/default.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
