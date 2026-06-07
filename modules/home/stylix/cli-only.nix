{ config, lib, ... }:
{
  options.stylix.cliOnly = lib.mkEnableOption "CLI-only mode for Stylix (disables GUI targets that require dconf/GTK)";

  config = lib.mkIf (config.stylix.enable && config.stylix.cliOnly) {
    stylix.targets.gtk.enable = lib.mkDefault false;
    stylix.targets.gtksourceview.enable = lib.mkDefault false;
    stylix.targets.gnome.enable = lib.mkDefault false;
    stylix.targets.gnome-text-editor.enable = lib.mkDefault false;
    stylix.targets.eog.enable = lib.mkDefault false;
  };
}
