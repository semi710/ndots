{ flake, ... }:
{
  # Stylix comes for nix-darwin and NixOs and home-manager.
  # This one is only for home-manager.
  imports = [
    flake.inputs.stylix.homeModules.stylix
    ./config.nix
    ./cli-only.nix
  ];

  # stylix's rofi module sets programs.rofi.font, renamed to
  # programs.rofi.settings.font in home-manager; unused (hyprland
  # self-themes rofi) - drop until stylix catches up
  disabledModules = [ "${flake.inputs.stylix}/modules/rofi/hm.nix" ];
}
