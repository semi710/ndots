{ flake, ... }:
{
  imports = [ ../virt/default.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
