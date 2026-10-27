{ lib, ... }:
let
  floaters =
    list:
    lib.map (appID: {
      check-further-callbacks = false;
      "if".app-name-regex-substring = appID;
      run = [
        "layout floating"
      ];
    }) list;
  comms =
    list:
    lib.map (appID: {
      check-further-callbacks = true;
      "if".during-aerospace-startup = true;
      "if".app-name-regex-substring = appID;
      run = [
        "layout tiling"
        "move-node-to-workspace Comms"
      ];
    }) list;
  floatingApps = floaters [
    # Apple apps
    "Screen Sharing"
    "Shottr"
    "Preferences"
    "activitymonitor"
    "addressbook"
    "appstore"
    "automator"
    "calculator"
    "colorsyncutility"
    "diskutility"
    "email"
    "facetime"
    "finder"
    "findmy"
    "freefrom"
    "gladys"
    "home"
    "iPhone Mirroring"
    "ical"
    "imageoptim"
    "kandji"
    "karabiner"
    "lulu"
    "mail"
    "maps"
    "messages"
    "mpv"
    "notes"
    "passwords"
    "photos"
    "picture-in-picture"
    "spotify"
    "systempreferences"
    "voicememos"
    "weather"
    "whatsapp"
    "zoom.us"
  ];

  commApps = comms [
    "telegram"
    "slack"
    "discord"
    "spotify"
    "whatsapp"
    "zoom.us"
    "signal"
  ];
in
{
  programs.aerospace = {
    enable = true;
    # let home-manager own the launchd agent; aerospace self-managed startup conflicts
    launchd.enable = true;
    settings = {
      start-at-login = true;
      accordion-padding = 120;
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
      # on-focus-changed = [ "move-mouse window-lazy-center" ];
      automatically-unhide-macos-hidden-apps = true;
      on-window-detected = floatingApps ++ commApps;
      exec.inherit-env-vars = true;
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      workspace-to-monitor-force-assignment = {
        "1" = "primary";
        "2" = "primary";
        "3" = "primary";
        "4" = "primary";
        "5" = "primary";
        "6" = [
          "secondary"
          "primary"
        ];
        "7" = [
          "secondary"
          "primary"
        ];
        "8" = [
          "secondary"
          "primary"
        ];
        "9" = [
          "secondary"
          "primary"
        ];
        "10" = "secondary";
      };
      after-startup-command = [
        # Handled by service but still here to ensure it runs
        "exec-and-forget borders"
        "exec-and-forget kitten panel --single-instance --instance-group dmenu --start-as-hidden --lines=0 --columns=0 --detach cat"
      ];
    };
  };
}
