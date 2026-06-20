{ flake, ... }:
{
  imports = [ ../virt-common/default.nix ];
  nixpkgs.hostPlatform = "aarch64-linux";
}
