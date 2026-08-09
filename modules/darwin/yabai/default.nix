{ lib, pkgs, ... }:
let
  spaceLabels = {
    "1" = "1";
    "2" = "2";
    "3" = "comms";
    "4" = "4";
    "5" = "5";
    "6" = "6";
    "7" = "7";
    "8" = "8";
    "9" = "9";
  };

  relabelCmd = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (idx: label: "yabai -m space ${idx} --label ${label}") spaceLabels
  );

  notManaged =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^${name}$\" manage=off") list
    );

  comms =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^.*${name}$\" space=comms") list
    );

  floating =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^.*${name}$\" manage=off") list
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
  floatingApps = [
    "ChatGPT"
  ];

  space-move-display = pkgs.writeShellScriptBin "space-move-display" ''
    ${lib.getExe pkgs.putils.yabai-space-move-display} "''${1:-next}"
    ${relabelCmd}
  '';
in
{
  imports = [ ./skhd.nix ]; # for keyamps
  environment.systemPackages = [ space-move-display ];
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

        ${relabelCmd}

        ${notManaged unmanagedApps}
        ${comms commsApps}
        ${floating floatingApps}
        yabai -m rule --apply
      '';
  };
}
