{
  config,
  flake,
  lib,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me // {
    username = "nikhil";
  };
in
{
  imports = [
    flake.homeModules.default
    flake.homeModules.ai
    flake.homeModules.stylix # for consistent theming across devices
  ];
  stylix.cliOnly = true;
  # omp dark theme follows the stylix palette (fallback is kanagawa-dragon)
  ndots.ai.omp.base16Colors = lib.filterAttrs (
    n: _: builtins.match "base[0-9A-F]{2}" n != null
  ) config.lib.stylix.colors;
  home.username = me.username;
  programs.zsh.initContent = ''
    export TERM="xterm-256color"
    export ZSH_DISABLE_COMPFIX="true"
  '';
  programs.git = {
    settings = {
      user = {
        name = me.fullname;
        email = me.email;
      };
    };
    includes = [
      {
        condition = "gitdir:~/work/bitbucket/";
        contents.user.email = "${me.username}.singh@juspay.in";
      }
    ];
  };
}
