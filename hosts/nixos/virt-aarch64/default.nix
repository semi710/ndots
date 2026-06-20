{ flake, ... }:
{
  imports = [ ../virt/default.nix ];
  nixpkgs.hostPlatform = "aarch64-linux";
}
