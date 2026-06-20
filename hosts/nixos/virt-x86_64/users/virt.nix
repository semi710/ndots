# Contains override for packages/moduels
# Most of my modules are meant to be used by multiple users
# and multiple people online.
# here in this config file i override them according to my needs
{
  flake,
  pkgs,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me // {
    username = "virt";
  };
in
{
  # users specific home modules
  imports = [ flake.homeModules.sops ];

  # comes from homeModules.editor
  nvix.variant = "core";

  # Color override for tmux plugin
  programs.tmux.plugins = [
    {
      plugin = pkgs.tmuxPlugins.minimal-tmux-status;
      extraConfig = ''
        set -g @minimal-tmux-use-arrow true
        set -g @minimal-tmux-right-arrow ""
        set -g @minimal-tmux-left-arrow ""
      '';
    }
  ];
  # git override for my personal/work email setup
  programs.git = {
    settings = {
      users = {
        name = me.fullname;
        email = me.email;
      };
    };
  };
}
