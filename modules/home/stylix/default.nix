{ flake, ... }:
{
  # Stylix comes for nix-darwin and NixOs and home-manager.
  # This one is only for home-manager.
  imports = [
    flake.inputs.stylix.homeModules.stylix
    ./config.nix
    ./cli-only.nix
  ];
}
