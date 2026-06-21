{
  inputs,
  pkgs,
  ...
}:
let
  hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hypr-pkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = inputs.nix-wire.lib.autoImport ./.;

  hm.wayland.windowManager.hyprland.package = null;
  hm.wayland.windowManager.hyprland.portalPackage = null;
  security.pam.services.hyprlock.text = "auth include login";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.hyprland = {
    enable = true;
    package = hyprPkgs.hyprland.override {
      enableXWayland = true;
      withSystemd = true;
    };
    withUWSM = true;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
  };
  hardware.graphics = {
    package = hypr-pkgs.mesa;
    enable32Bit = true;
    package32 = hypr-pkgs.pkgsi686Linux.mesa;
  };

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
