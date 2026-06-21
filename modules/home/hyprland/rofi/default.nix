{
  inputs,
  pkgs,
  lib,
  ...
}:
with lib;
{
  stylix.targets.rofi.enable = false;

  wayland.windowManager.hyprland.settings = {
    layerrule = [
      # "ignorezero, waybar"
      # "blur, waybar"
      # "blur, rofi"
    ];
  };
  programs.rofi = {
    package = pkgs.rofi-wayland;
    theme = "black";
    extraConfig = {
      show-icons = true;
      drun-display-format = "{name}";
      hide-scrollbar = true;
      sidebar-mode = false;
      kb-remove-to-eol = "Control+p";
      kb-secondary-copy = "Control+c";
      kb-accept-entry = "Return";
      kb-mode-complete = "";
      kb-remove-char-back = "BackSpace";
      kb-row-up = "Up,Control+k";
      kb-row-down = "Down,Control+j";
      kb-row-right = "Control+l";
      kb-row-left = "Control+h";
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = [
        "MousePrimary"
        "MouseSecondary"
      ];
      terminal = "kitty";
      font = "${config.stylix.fonts.monospace.name} 12";
    };
  };

  imports = inputs.nix-wire.lib.autoImport ./.;
}
