{ pkgs, lib, ... }:
let
  # I map holding of `capslock` key to `cmd+alt` in karabiner-elements
  mod = "cmd-alt";
  aerospaceBin = lib.getExe pkgs.aerospace;
  displayInfo = # sh
    ''
      monitor_name=$(${aerospaceBin} list-monitors --focused --format '%{monitor-name}')
      case $monitor_name in
        "Built-in Retina Display")
          monitor_name="Color LCD";;
        *) ;;
      esac

      # display information of the focused monitor
      jq_filter=".SPDisplaysDataType[].spdisplays_ndrvs[] | select(._name == \"''${monitor_name}\") | ._spdisplays_resolution"
      display_info=$(system_profiler SPDisplaysDataType -json | jq -r "''${jq_filter}")

      screen_width=$(echo "''${display_info}" | cut -d ' ' -f 1)
      screen_height=$(echo "''${display_info}" | cut -d ' ' -f 3)
    '';
  movefloating = pkgs.writeShellScriptBin "movefloating" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"
    ${displayInfo}
    osascript -e "
    tell application \"System Events\"
      set _app to name of first application process whose frontmost is true
      tell process _app
        set _window to front window
        set {x0, y0, width, height} to _window's position & _window's size
        set {x1, y1} to {x0 + $1, y0 + $2}
        if x1 + width <= $screen_width then
          if y1 + height <= $screen_height then
            set position of _window to {my max(7, x1), my max(45, y1)}
          end if
        end if
        activate
      end tell
    end tell

    on max(x, y)
      if x >= y then return x
      return y
    end max
    "
  '';
  resizefloating = pkgs.writeShellScriptBin "resizefloating" ''
    osascript -e "
    tell application \"System Events\"
      set _app to name of first application process whose frontmost is true
      tell process _app
        set _window to front window
        set {x, y, width, height} to _window's position & _window's size
        set position of _window to {x - ($1 / 2), y - ($2 / 2)}
        set size of _window to {width + $1, height + $2}
        activate
      end tell
    end tell
    "
  '';
  centerfloating = pkgs.writeShellScriptBin "centerfloating" ''
    export PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"
    print_screen_size() {
      # find focused monitor
      local monitor_name
      monitor_name=$(${aerospaceBin} list-monitors --focused --format '%{monitor-name}')
      case $monitor_name in
        "Built-in Retina Display")
          monitor_name="Color LCD";;
        *) ;;
      esac

      # check cache
      if [[ -e "/tmp/centralize-focused-window/display-info-''${monitor_name}" ]]; then
        cat "/tmp/centralize-focused-window/display-info-''${monitor_name}"
        return
      fi

      # display information of the focused monitor
      local jq_filter
      local display_info
      local screen_width
      local screen_height
      jq_filter=".SPDisplaysDataType[].spdisplays_ndrvs[] | select(._name == \"''${monitor_name}\") | ._spdisplays_resolution"
      display_info=$(system_profiler SPDisplaysDataType -json | jq -r "''${jq_filter}")

      # print screen size
      screen_width=$(echo "''${display_info}" | cut -d ' ' -f 1)
      screen_height=$(echo "''${display_info}" | cut -d ' ' -f 3)
      mkdir -p /tmp/centralize-focused-window
      echo "''${screen_width} ''${screen_height}" >> "/tmp/centralize-focused-window/display-info-''${monitor_name}"
      cat "/tmp/centralize-focused-window/display-info-''${monitor_name}"
    }

    centralize-focused-window() {
      local screen_size
      local screen_width
      local screen_height
      screen_size=$(print_screen_size)
      screen_width=$(echo "''${screen_size}" | cut -d ' ' -f 1)
      screen_height=$(echo "''${screen_size}" | cut -d ' ' -f 2)
      osascript <<EOF
    set w to ''${screen_width} / 5 * 3
    set h to ''${screen_height} / 5 * 3
    set x to (''${screen_width} - w) / 2
    set y to (''${screen_height} - h) / 2

    tell application "System Events" to tell first application process whose frontmost is true
      set position of first window to {x, y}
      set position of last window to {x, y}
      set size of first window to {w, h}
      set size of last window to {w, h}
    end tell
    EOF
    }

    centralize-focused-window
  '';
  movefloatingCmd = lib.getExe movefloating;
  centerfloatingCmd = lib.getExe centerfloating;
  resizefloatingCmd = lib.getExe resizefloating;
in
{
  programs.aerospace.userSettings.mode.main.binding = {
    "${mod}-shift-left" = "exec-and-forget ${movefloatingCmd} -100 0"; # move left
    "${mod}-shift-right" = "exec-and-forget ${movefloatingCmd} 100 0"; # move left
    "${mod}-shift-up" = "exec-and-forget ${movefloatingCmd} 0 -100"; # move left
    "${mod}-shift-down" = "exec-and-forget ${movefloatingCmd} 0 100"; # move left
    "${mod}-ctrl-c" = "exec-and-forget ${centerfloatingCmd}"; # center floating window

    "${mod}-ctrl-h" = "exec-and-forget ${resizefloatingCmd} -100 0"; # move left
    "${mod}-ctrl-l" = "exec-and-forget ${resizefloatingCmd} 100 0"; # move left
    "${mod}-ctrl-k" = "exec-and-forget ${resizefloatingCmd} 0 -100"; # move left
    "${mod}-ctrl-j" = "exec-and-forget ${resizefloatingCmd} 0 100"; # move left
  };
}
