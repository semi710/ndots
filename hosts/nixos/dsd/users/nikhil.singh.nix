# Contains override for packages/moduels
# Most of my modules are meant to be used by multiple users
# and multiple people online.
# here in this config file i override them according to my needs
{
  flake,
  config,
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
    flake.homeModules.ai
    flake.homeModules.terminal
    flake.homeModules.syncthing
  ];

  services.syncthing = {
    # CPU is in office and ssh key get's there by ssh-agent forwarding, so skipping sops here
    # Passwordfile is to be expected in a manual path
    guiCredentials = {
      username = me.username;
      passwordFile = "${config.home.homeDirectory}/.syncthing.pass";
    };

    settings = {
      gui.user = me.username;
    };
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
