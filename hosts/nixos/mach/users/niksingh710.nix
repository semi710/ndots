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

  sops.secrets = {
    "tokens/ai/gemini" = { };
    "tokens/ai/openai" = { };
    "tokens/ai/openrouter" = { };
    "tokens/ai/opencode-zen" = { };
    "tokens/github" = { };
    "tokens/cachix" = { };
    "ssh/private" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };
    "rclone/conf".path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    "rclone/locked-conf".path = "${config.home.homeDirectory}/.config/rclone/rclone.conf.lock";
    "syncthing/mach/password" = { };
    "syncthing/mach/cert" = { };
    "syncthing/mach/key" = { };
    "naste/user" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "naste/pass" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };

    # office keys
    "private-keys/jp-key" = {
      sopsFile = "${flake}/secrets/office.yaml";
    };
  };

  programs.naste-client.private = {
    userFile = config.sops.secrets."naste/user".path;
    passFile = config.sops.secrets."naste/pass".path;
  };

  services.syncthing = {
    guiCredentials = {
      username = me.username;
      passwordFile = config.sops.secrets."syncthing/mach/password".path;
    };
    cert = config.sops.secrets."syncthing/mach/cert".path;
    key = config.sops.secrets."syncthing/mach/key".path;
  };

  home.sessionVariables = {
    OPENAI_API_BASE = "https://api.githubcopilot.com";
    OPENAI_API_KEY = "$(cat ${config.sops.secrets."tokens/ai/openai".path})";
    OPENROUTER_API_KEY = "$(cat ${config.sops.secrets."tokens/ai/openrouter".path})";
    OPENCODE_API_KEY = "$(cat ${config.sops.secrets."tokens/ai/opencode-zen".path})";
    GEMINI_API_KEY = "$(cat ${config.sops.secrets."tokens/ai/gemini".path})";
    GITHUB_TOKEN = "$(cat ${config.sops.secrets."tokens/github".path})";
    JUSPAY_API_KEY = "$(cat ${config.sops.secrets."private-keys/jp-key".path})";

    CACHIX_AUTH_TOKEN = "$(cat ${config.sops.secrets."tokens/cachix".path})";
  };

  nvix.variant = "full";

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
