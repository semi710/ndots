{ flake, ... }:
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
