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
  jp = (import (flake + "/config.nix")).users.jp;
  me = (import (flake + "/config.nix")).users.me;
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

  home.packages = with pkgs; [ sklauncher-beta ];

  services.syncthing = {
    guiCredentials = {
      username = jp.username;
      passwordFile = config.sops.secrets."syncthing/jp-mbp/password".path;
    };
    cert = config.sops.secrets."syncthing/jp-mbp/cert".path;
    key = config.sops.secrets."syncthing/jp-mbp/key".path;
  };

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
    "ssh/office" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
      mode = "0600";
    };
    "syncthing/jp-mbp/password" = { };
    "syncthing/jp-mbp/cert" = { };
    "syncthing/jp-mbp/key" = { };
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

  # Allow nix flake fetcher to find the work SSH key regardless of directory.
  # Nix's internal git fetcher doesn't use git's core.sshCommand (which is
  # gated behind gitdir:~/work/bitbucket/), so without this Host block it
  # has no key to offer and gets Permission denied.
  programs.ssh.settings = {
    "ssh.bitbucket.juspay.net" = {
      identityFile = "~/.ssh/id_ed25519_work";
      identitiesOnly = true;
    };
  };

  # Patch Zen bundle ID so Kandji MDM profile (targeting app.zen-browser.zen) doesn't match.
  # This prevents enterprise extension blocking from taking effect.
  #
  # nixpkgs 26.05 wrapFirefox has a bug: the buildCommand heredoc doesn't quote
  # ${browser.applicationName}, so "Zen Browser (Beta)" (with parentheses) causes
  # a bash syntax error when eval'd. We fix the unquoted references and pass
  # policies through the wrapper (the HM module skips policies when
  # unwrappedPackage is set).
  programs.zen-browser = {
    unwrappedPackage =
      flake.inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs
        (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier app.zen-browser.zen-oss" \
              "$out/Applications/Zen Browser (Beta).app/Contents/Info.plist"
          '';
        });
    package =
      (pkgs.wrapFirefox config.programs.zen-browser.unwrappedPackage {
        inherit (config.programs.zen-browser) extraPrefs extraPrefsFiles nativeMessagingHosts;
        extraPolicies = config.programs.zen-browser.policies;
        icon = "zen-browser";
      }).overrideAttrs
        (old: {
          # Fix nixpkgs wrapFirefox bug: unquoted "Zen Browser (Beta)" in buildCommand.
          # Replace the single unquoted $out path with a quoted version.
          buildCommand =
            builtins.replaceStrings
              [ "touch $out/Applications/Zen Browser (Beta).app" ]
              [ "touch \"$out/Applications/Zen Browser (Beta).app\"" ]
              old.buildCommand;
        });
  };

  # Safari & system default search engine
  targets.darwin.search = "DuckDuckGo";

  targets.darwin.defaults."com.apple.Safari" = {
    AutoOpenSafeDownloads = false;
    IncludeDevelopMenu = true;
    ShowOverlayStatusBar = true;
    SearchProviderShortName = "DuckDuckGo";
    "WebKitPreferences.developerExtrasEnabled" = true;
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
}
