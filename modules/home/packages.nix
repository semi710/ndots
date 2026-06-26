# Not meant to be imported by other user
# but can use if you understand and need these
# some packages are might be coming from my overlays
# Most of the packages are ui based.
# if cli based increases then a dir/{cli.nix, default.nix} can be created
# with partial import
{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin isLinux;

  both = with pkgs; [
    google-chrome
    # quickemu # OVMF to be fixed
    telegram-desktop
  ];

  linux = lib.optionals isLinux ([ ]);
  darwin = lib.optionals isDarwin (
    with pkgs;
    [
      mas
      bruno
      ytmdesktop
      bruno-cli
      drag

      # Mac ui apps are preferred to be from homebrew via or mas
      # check ./../../modules/darwin/brew.nix for more apps

      # Custom package with premium version
      # Android connector
      # airsync
    ]
  );

in
{
  home.packages = linux ++ darwin ++ both;

  imports = [
    inputs.nixcord.homeModules.nixcord
  ];
  programs.nixcord = {
    enable = true;
    config = {
      useQuickCss = true;
      frameless = true;
      plugins = {
        messageLogger = {
          enable = true;
          collapseDeleted = true;
        };
        showMeYourName.enable = true;
        fakeNitro.enable = true;
      };
    };
  };
}
