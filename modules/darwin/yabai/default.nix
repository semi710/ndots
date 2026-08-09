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

  # Single source of truth: space label -> list of app names (prefix-matched)
  appSpaces = {
    "1" = [ "kitty" ];
    "2" = [ "Zen" ];
    "comms" = [
      "Slack"
      "Discord"
      "Telegram"
      "Signal"
    ];
  };

  relabelCmd = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (idx: label: "yabai -m space ${idx} --label ${label}") spaceLabels
  );

  # Generate yabai rules from appSpaces
  spaceRules = lib.concatStringsSep "\n" (
    lib.flatten (
      lib.mapAttrsToList (
        space: apps: lib.map (app: "yabai -m rule --add app=\"^${app}.*$\" space=${space}") apps
      ) appSpaces
    )
  );

  # Generate bash case branches for space-reset sorting
  sortCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      space: apps:
      let
        patterns = lib.concatStringsSep "|" (map (app: "${app}*") apps);
      in
      "${patterns}) yabai -m window \"$wid\" --space ${space} ;;"
    ) appSpaces
  );

  notManaged =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^${name}$\" manage=off") list
    );

  floating =
    list:
    builtins.concatStringsSep "\n" (
      lib.map (name: "yabai -m rule --add app=\"^.*${name}$\" manage=off") list
    );

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
    yabai -m rule --apply
  '';

  # Destroy the visible space under the cursor (works on empty spaces)
  space-destroy = pkgs.writeShellScriptBin "space-destroy" ''
    visible=$(yabai -m query --spaces --display mouse | ${lib.getExe pkgs.jq} -r '.[] | select(."is-visible") | .index')
    [ -n "$visible" ] && yabai -m space "$visible" --destroy
    ${relabelCmd}
    yabai -m rule --apply
  '';

  # Reset spaces: display 1 gets 7, other displays get 8-9, relabel, and sort windows
  space-reset = pkgs.writeShellScriptBin "space-reset" ''
    jq=${lib.getExe pkgs.jq}

    # Destroy all spaces except one per display (can't destroy the last)
    for disp in $(yabai -m query --displays | $jq -r '.[].index'); do
      count=$(yabai -m query --spaces --display "$disp" | $jq 'length')
      while [ "$count" -gt 1 ]; do
        last=$(yabai -m query --spaces --display "$disp" | $jq -r '.[-1].index')
        yabai -m space "$last" --destroy 2>/dev/null || break
        count=$((count - 1))
      done
    done

    # Create spaces on display 1 until it has 7
    d1_count=$(yabai -m query --spaces --display 1 | $jq 'length')
    while [ "$d1_count" -lt 7 ]; do
      yabai -m space --create 1 2>/dev/null
      d1_count=$((d1_count + 1))
    done

    # Create 2 spaces on last display (8, 9)
    last_disp=$(yabai -m query --displays | $jq -r '.[-1].index')
    d2_count=$(yabai -m query --spaces --display "$last_disp" | $jq 'length')
    while [ "$d2_count" -lt 2 ]; do
      yabai -m space --create "$last_disp" 2>/dev/null
      d2_count=$((d2_count + 1))
    done

    ${relabelCmd}
    yabai -m rule --apply

    # Move windows to their assigned workspaces
    yabai -m query --windows | $jq -c '.[] | {id, app}' | while read -r line; do
      wid=$(echo "$line" | $jq -r '.id')
      app=$(echo "$line" | $jq -r '.app')
      case "$app" in
        ${sortCases}
      esac
    done
  '';
in
{
  imports = [ ./skhd.nix ]; # for keyamps
  environment.systemPackages = [
    space-move-display
    space-destroy
    space-reset
  ];
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
        ${spaceRules}
        ${floating floatingApps}
        yabai -m rule --apply
      '';
  };
}
