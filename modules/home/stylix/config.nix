{ pkgs, ... }:
let
  # pick any name from <https://tinted-theming.github.io/tinted-gallery/>
  # if base16Scheme is not set the color from wallpapers will be used
  scheme = "kanagawa-dragon";
in
{
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${scheme}.yaml";
    image = pkgs.fetchurl {
      url = "https://gruvbox-wallpapers.pages.dev/wallpapers/pixelart/gruvbox_image55.png";
      sha256 = "sha256-lgZbAAWTimybsBD+2ZsS/jwKtyPbQ1QCgt/82RDIHug=";
    };
    opacity.terminal = 0.4;
    polarity = "dark";
    fonts.monospace = {
      name = "Monaspace Radon Var";
      package = pkgs.monaspace;
    };
  };
}
