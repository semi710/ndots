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
  me = (import (flake + "/config.nix")).me;
in
{
  # users specific home modules
  imports = [
    flake.homeModules.sops
    flake.homeModules.ai
    flake.homeModules.terminal
    flake.homeModules.syncthing
  ];

  sops.secrets = {
    "private-keys/gemini_api" = { };
    "private-keys/openai_api" = { };
    "private-keys/github_token" = { };
    "private-keys/jp-key" = { };
    "private-keys/cachix_token" = { };
    "private-keys/ssh" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };
    "rclone/conf".path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    "rclone/locked-conf".path = "${config.home.homeDirectory}/.config/rclone/rclone.conf.lock";
    "syncthing/mach/password" = { };
    "syncthing/mach/cert" = { };
    "syncthing/mach/key" = { };
  };

  services.syncthing = {
    guiCredentials = {
      username = me.username;
      passwordFile = config.sops.secrets."syncthing/mach/password".path;
    };
    settings = {
      gui.user = me.username;
    };
    cert = config.sops.secrets."syncthing/mach/cert".path;
    key = config.sops.secrets."syncthing/mach/key".path;
  };

  home.sessionVariables = {
    OPENAI_API_BASE = "https://api.githubcopilot.com";
    OPENAI_API_KEY = "$(cat ${config.sops.secrets."private-keys/openai_api".path})";
    GEMINI_API_KEY = "$(cat ${config.sops.secrets."private-keys/gemini_api".path})";
    GITHUB_TOKEN = "$(cat ${config.sops.secrets."private-keys/github_token".path})";
    JUSPAY_API_KEY = "$(cat ${config.sops.secrets."private-keys/jp-key".path})";
    SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
    CACHIX_AUTH_TOKEN = "$(cat ${config.sops.secrets."private-keys/cachix_token".path})";
  };

  # comes from homeModules.editor
  nvix.variant = "full";

  programs.git = {
    settings = {
      user = {
        name = me.fullname;
        email = me.email;
      };
    };
  };
}
