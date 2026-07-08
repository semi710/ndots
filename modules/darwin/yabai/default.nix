{ lib, ... }:
let
  notManaged =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^${name}$\" manage=off") list
    );

  comms =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^*${name}$\" space=comms") list
    );

  commsApps = [
    "Slack"
    "Discord"
    "Telegram"
    "Signal"
  ];
  unmanagedApps = [
    "System Settings"
    "Wallnetic"
    "Calculator"
    "Kaset"
    "Karabiner-Elements"
    "Screen Sharing"
    "iPhone Mirroring"
    "ical"
    "weather"
    "passwords"
    "Proton VPN"
    "FaceTime"
    "Finder"
    "LuLu"
    "mpv"
    "Mail"
    "AirSync"
    "WhatsApp"
    "Messages"
    "Tailscale"
    "hiddenbar"
  ];
in
{
  imports = [ ./skhd.nix ]; # for keyamps
  services.yabai = {
    enable = true;
    enableScriptingAddition = true; # Requires SIP to be disabled Partially
    config = {
      active_window_opacity = 1.0;
      auto_balance = "on";
      focus_follows_mouse = "autofocus";
      layout = "bsp";
      mouse_drop_action = "swap";
      mouse_follows_focus = "on";
      mouse_modifier = "alt";
      normal_window_opacity = 0.98;
      bottom_padding = 10;
      right_padding = 10;
      left_padding = 10;
      top_padding = 10;
      window_gap = 10;
      window_opacity = "on";
      window_placement = "second_child";
      window_shadow = "float";
    };
    extraConfig = # sh
      ''
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
        sudo yabai --load-sa

        yabai -m signal --add event=mission_control_enter action="yabai -m config normal_window_opacity 1.0"
        yabai -m signal --add event=mission_control_exit action="yabai -m config active_window_opacity 1.0"

        ${notManaged unmanagedApps}
        ${comms commsApps}
        yabai -m rule --apply

        yabai -m space 1 --label 1
        yabai -m space 2 --label 2
        yabai -m space 3 --label comms
        yabai -m space 4 --label 4
        yabai -m space 5 --label 5
        yabai -m space 6 --label 6
        yabai -m space 7 --label 7
        yabai -m space 8 --label 8
        yabai -m space 9 --label 9
      '';
  };
}
