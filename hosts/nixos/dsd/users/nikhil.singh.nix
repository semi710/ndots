{
  flake,
  config,
  lib,
  ...
}:
let
  jp = (import (flake + "/config.nix")).users.jp;
  host = (import (flake + "/config.nix")).users.me;
in
{
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

  home.file = {
    ".ssh/id_ed25519.pub".text = builtins.elemAt host.sshPublicKeys 0;
    ".ssh/id_ed25519_work.pub".text = builtins.elemAt jp.sshPublicKeys 0;
  };

  nvix.variant = "core";
  programs.opencode.web = {
    enable = true;
    environmentFile = "${config.home.homeDirectory}/.opencode.env";
  };
  ndots.ai.mcp.workServers = true;
  ndots.ai.omp.base16Colors = lib.filterAttrs (
    n: _: builtins.match "base[0-9A-F]{2}" n != null
  ) config.lib.stylix.colors;

  programs.git = {
    settings = {
      user = {
        name = host.fullname;
        email = host.email;
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

  programs.ssh.settings = {
    "ssh.bitbucket.juspay.net" = {
      identityFile = "~/.ssh/id_ed25519_work";
      identitiesOnly = true;
    };
  };
}
