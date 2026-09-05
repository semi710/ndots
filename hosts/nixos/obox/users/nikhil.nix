# Home-manager config for nikhil on obox.
{
  flake,
  config,
  ...
}:
let
  host = (import (flake + "/config.nix")).users.obox;
in
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.nix-index
    flake.homeModules.sops
    flake.homeModules.syncthing
  ];

  sops.secrets = {
    "naste/user" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "naste/pass" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "syncthing/obox/password" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "syncthing/obox/cert" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "syncthing/obox/key" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
  };

  programs.naste-client.private = {
    userFile = config.sops.secrets."naste/user".path;
    passFile = config.sops.secrets."naste/pass".path;
  };

  services.syncthing = {
    guiCredentials = {
      username = host.username;
      passwordFile = config.sops.secrets."syncthing/obox/password".path;
    };
    cert = config.sops.secrets."syncthing/obox/cert".path;
    key = config.sops.secrets."syncthing/obox/key".path;
  };
}
