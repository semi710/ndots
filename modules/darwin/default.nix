{ flake, ... }:
{
  imports = [
    flake.flakeModules.nix

    flake.darwinModules.settings
    flake.darwinModules.brew
    flake.darwinModules.stylix
    flake.darwinModules.sharedModules
  ];

  # Backup conflicting home files instead of failing activation
  home-manager.backupFileExtension = "backup";
}
