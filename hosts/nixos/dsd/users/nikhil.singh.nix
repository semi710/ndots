# Contains override for packages/moduels
# Most of my modules are meant to be used by multiple users
# and multiple people online.
# here in this config file i override them according to my needs
{
  flake,
  config,
  lib,
  ...
}:
let
  me = (import (flake + "/config.nix")).me // {
    username = "nikhil.singh";
  };
in
{
  # users specific home modules
  imports = [
    flake.homeModules.sops
    flake.homeModules.ai
    flake.homeModules.terminal
    flake.homeModules.syncthing
  ];

  sops = {
    defaultSopsFile = lib.mkForce "${flake}/secrets/office.yaml";
    secrets = {
      "syncthing/dsd/password" = { };
      "syncthing/dsd/cert" = { };
      "syncthing/dsd/key" = { };
    };
  };

  services.syncthing = {
    guiCredentials = {
      username = me.username;
      passwordFile = config.sops.secrets."syncthing/dsd/password".path;
    };
    cert = config.sops.secrets."syncthing/dsd/cert".path;
    key = config.sops.secrets."syncthing/dsd/key".path;
  };
  # comes from homeModules.editor
  nvix.variant = "core";
  programs.opencode.web = {
    enable = true;
    environmentFile = "${config.home.homeDirectory}/.opencode.env";
  };

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
