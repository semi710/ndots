{ flake, ... }:
let
  me = (import (flake + "/config.nix")).users.me // {
    username = "nikhil.singh";
  };
in
{
  imports = [
    flake.homeModules.default
    flake.homeModules.ai
  ];
  home.username = "nikhil";
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
        contents.user.email = "${me.username}@juspay.in";
      }
    ];
  };
}
