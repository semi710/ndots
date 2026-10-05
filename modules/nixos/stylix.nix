{ flake, ... }:
{
  # Stylix comes for nix-darwin and NixOs and home-manager.
  imports = [
    flake.inputs.stylix.nixosModules.stylix
    (flake + /modules/home/stylix/config.nix)
  ];

  home-manager.sharedModules = [
    { stylix.enableReleaseChecks = false; }
    {
      # stylix's rofi module sets programs.rofi.font, renamed to
      # programs.rofi.settings.font in home-manager; no host uses the target
      # (darwin has no rofi, hyprland self-themes it) so drop the module
      # until stylix catches up
      disabledModules = [ "${flake.inputs.stylix}/modules/rofi/hm.nix" ];
    }
  ];
}
