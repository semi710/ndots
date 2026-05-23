# Contains override for packages/moduels
# Most of my modules are meant to be used by multiple users
# and multiple people online.
# here in this config file i override them according to my needs
{
  flake,
  pkgs,
  lib,
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
    (flake.homeModules.darwin + "/jankyborders.nix")
    (flake.homeModules.darwin + "/karabiner.nix")
    (flake.homeModules.darwin + "/hammerspoon.nix")

    flake.homeModules.sops
    flake.homeModules.ai
    flake.homeModules.syncthing
  ];

  services.syncthing = {
    guiCredentials = {
      username = me.username;
      passwordFile = config.sops.secrets."syncthing/jp-mbp/password".path;
    };
    cert = config.sops.secrets."syncthing/jp-mbp/cert".path;
    key = config.sops.secrets."syncthing/jp-mbp/key".path;
  };

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
    "private-keys/ssh-office" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
      mode = "0600";
    };
    "syncthing/jp-mbp/password" = { };
    "syncthing/jp-mbp/cert" = { };
    "syncthing/jp-mbp/key" = { };
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

  # Color override for tmux plugin
  programs.tmux.plugins = [
    {
      plugin = pkgs.tmuxPlugins.minimal-tmux-status;
      extraConfig = ''
        set -g @minimal-tmux-bg "#${config.lib.stylix.colors.base01}"
        set -g @minimal-tmux-fg "#${config.lib.stylix.colors.base06}"
      '';
    }
  ];
  # git override for my personal/work email setup
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
  stylix.targets.fzf.enable = false;
  # Kitty terminal override
  programs.kitty = {
    font.size = lib.mkForce 16;
  };

  # color override as it comes from stylix
  services.jankyborders.settings.active_color = "0xff${config.lib.stylix.colors.base06}";

  # Telegram theming via stylix, using walogram package
  home.activation.tg-theme = lib.hm.dag.entryAfter [ "" ] ''
    run ${
      lib.getExe (
        pkgs.putils.walogram.override {
          image = "${config.stylix.image}";
          colors = (
            with config.lib.stylix.colors;
            ''
              color0="#${base00}"
              color1="#${base01}"
              color2="#${base02}"
              color3="#${base03}"
              color4="#${base04}"
              color5="#${base05}"
              color6="#${base06}"
              color7="#${base07}"
              color8="#${base08}"
              color9="#${base09}"
              color10="#${base0A}"
              color11="#${base0B}"
              color12="#${base0C}"
              color13="#${base0D}"
              color14="#${base0E}"
              color15="#${base0F}"
            ''
          );
        }
      )
    }
  '';

  home.activation.fix-nix-conf-extra-prefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nixConfFile="${config.home.homeDirectory}/.config/nix/nix.conf"

    if [[ -f "$nixConfFile" ]]; then
      if $DRY_RUN_CMD grep -qE '^[[:space:]]*(substituters|trusted-public-keys)[[:space:]]*=' "$nixConfFile"; then
        $VERBOSE_ECHO "Converting ~/.config/nix/nix.conf list settings to extra- prefix..."

        tmpFile="''$nixConfFile.tmp.$$"
        while IFS= read -r line || [[ -n "$line" ]]; do
          if [[ "$line" =~ ^[[:space:]]*substituters[[:space:]]*= ]] && \
             ! [[ "$line" =~ ^[[:space:]]*extra-substituters[[:space:]]*= ]]; then
            $DRY_RUN_CMD echo "$line" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*substituters/extra-substituters/' >> "$tmpFile"
          elif [[ "$line" =~ ^[[:space:]]*trusted-public-keys[[:space:]]*= ]] && \
               ! [[ "$line" =~ ^[[:space:]]*extra-trusted-public-keys[[:space:]]*= ]]; then
            $DRY_RUN_CMD echo "$line" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*trusted-public-keys/extra-trusted-public-keys/' >> "$tmpFile"
          else
            $DRY_RUN_CMD echo "$line" >> "$tmpFile"
          fi
        done < "$nixConfFile"

        $DRY_RUN_CMD mv "$tmpFile" "$nixConfFile"
        $VERBOSE_ECHO "Done: nix.conf list settings now use extra- prefix"
      fi
    fi
  '';
}
