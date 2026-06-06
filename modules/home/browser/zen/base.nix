{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  stylix.targets.zen-browser.enable = false;
  programs.zen-browser = {
    enable = true;
    profiles.default = {
      containersForce = true;
      containers = {
        Personal = {
          color = "purple";
          icon = "fingerprint";
          id = 1;
        };
        Work = {
          color = "blue";
          icon = "briefcase";
          id = 2;
        };
      };

      mods = [
        "fd24f832-a2e6-4ce9-8b19-7aa888eb7f8e" # Quietify - Visualizer animation for mute button
        "599a1599-e6ab-4749-ab22-de533860de2c" # Pimp your PiP - PiP tweaks and upgrades
        "642854b5-88b4-4c40-b256-e035532109df" # Transparent Zen - Transparent backgrounds
        "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better CtrlTab Panel - CtrlTab customization
        "e51b85e6-cef5-45d4-9fff-6986637974e1" # Smaller Zen Toast - Less distracting notifications
        "81fcd6b3-f014-4796-988f-6c3cb3874db8" # Zen Context Menu - Declutter right-click menu
        "bc25808c-a012-4c0d-ad9a-aa86be616019" # Sleek Border - Subtle opacity borders
        "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaned URL Bar - Cleaner URL bar
        "8039de3b-72e1-41ea-83b3-5077cf0f98d1" # Trackpad Animation - Gesture animations
      ];

      settings = {
        # Session restore
        "browser.startup.page" = 3;
        "browser.startup.homepage" = "about:blank";
        "browser.sessionstore.resume_from_crash" = true;
        "browser.sessionstore.restore_on_demand" = false;
        "browser.sessionstore.max_tabs_undo" = 100;
        "browser.sessionstore.max_windows_undo" = 20;

        # Workspaces
        "zen.workspaces.enabled" = true;
        "zen.workspaces.show-workspace-indicator" = true;
        "services.sync.engine.workspaces" = true;

        # Window sync
        "zen.window-sync.enabled" = true;
        "zen.window-sync.sync-only-pinned-tabs" = true;

        # Transparency (required for Transparent Zen mod)
        "browser.tabs.allow_transparent_browser" = true;
        "zen.theme.gradient.show-custom-colors" = true;

        # UI preferences
        "browser.aboutConfig.showWarning" = false;
        "browser.newtabpage.enabled" = false;
        "browser.download.deletePrivate" = true;
      };
    };

    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
      };
    };
  };

  xdg.mimeApps =
    let
      value =
        let
          zen-browser = config.programs.zen-browser.package;
        in
        zen-browser.meta.desktopFileName;

      associations = builtins.listToAttrs (
        map
          (name: {
            inherit name value;
          })
          [
            "application/x-extension-shtml"
            "application/x-extension-xhtml"
            "application/x-extension-html"
            "application/x-extension-xht"
            "application/x-extension-htm"
            "x-scheme-handler/unknown"
            "x-scheme-handler/mailto"
            "x-scheme-handler/chrome"
            "x-scheme-handler/about"
            "x-scheme-handler/https"
            "x-scheme-handler/http"
            "application/xhtml+xml"
            "application/json"
            "text/plain"
            "text/html"
          ]
      );
    in
    {
      associations.added = associations;
      defaultApplications = associations;
    };

  home.file.".config/mimeapps.list".text = lib.optionalString pkgs.stdenv.isLinux ''
    [Default Applications]
    x-scheme-handler/slack=zen-beta.desktop
    x-scheme-handler/discord=zen-beta.desktop
    x-scheme-handler/zoommtg=zen-beta.desktop
    x-scheme-handler/zoomus=zen-beta.desktop
    x-scheme-handler/tg=zen-beta.desktop
    x-scheme-handler/whatsapp=zen-beta.desktop
    x-scheme-handler/postman=zen-beta.desktop
    x-scheme-handler/element=zen-beta.desktop
  '';
}
