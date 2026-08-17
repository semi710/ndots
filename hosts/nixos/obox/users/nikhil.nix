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

  services.syncthing = {
    guiCredentials = {
      username = host.username;
      passwordFile = config.sops.secrets."syncthing/obox/password".path;
    };
    cert = config.sops.secrets."syncthing/obox/cert".path;
    key = config.sops.secrets."syncthing/obox/key".path;
  };
}
