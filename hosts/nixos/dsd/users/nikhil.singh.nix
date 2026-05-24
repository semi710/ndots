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
  jp = (import (flake + "/config.nix")).users.jp;
  me = (import (flake + "/config.nix")).users.me;
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
      username = jp.username;
      passwordFile = config.sops.secrets."syncthing/dsd/password".path;
    };
    cert = config.sops.secrets."syncthing/dsd/cert".path;
    key = config.sops.secrets."syncthing/dsd/key".path;
  };
  # Public keys for SSH agent key selection via -i
  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.elemAt me.sshPublicKeys 0;
    ".ssh/id_ed25519_work.pub".text = builtins.elemAt jp.sshPublicKeys 0;
  };
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
      core.sshCommand = "ssh -i ~/.ssh/id_ed25519.pub -o IdentitiesOnly=yes";
    };
    includes = [
      {
        condition = "gitdir:~/work/bitbucket/";
        contents = {
          user.name = jp.fullname;
          user.email = "${jp.username}@juspay.in";
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_work.pub -o IdentitiesOnly=yes";
        };
      }
    ];
  };
}
