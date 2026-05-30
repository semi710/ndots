{ flake, ... }:
{
  # Stylix comes for nix-darwin and NixOs and home-manager.
  imports = [
    flake.inputs.stylix.nixosModules.stylix
    (flake + /modules/home/stylix/config.nix)
  ];

  home-manager.sharedModules = [
    { stylix.enableReleaseChecks = false; }
  ];
}
