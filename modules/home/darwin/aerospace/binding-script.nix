{ pkgs, lib, ... }:
let
  # mirrors skhd's hyper chord so gestures are identical in yabai mode
  mod = "cmd-alt-ctrl";
  aerospaceBin = lib.getExe pkgs.aerospace;
  kblight = lib.getExe pkgs.kblight;
  # floating check - no %{is-window-floating}; window-layout reports "floating"
  isFloating = ''[ "$(${aerospaceBin} list-windows --focused --format '%{window-layout}')" = "floating" ]'';
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

  # skhd special hjkl - nudge floating window 40px, no-op on tiled
  float-move = pkgs.writeShellScriptBin "float-move" ''
    if ${isFloating}; then
      exec ${lib.getExe movefloating} "$1" "$2"
    fi
  '';
  # skhd special mod+hjkl - resize; native for tiled, osascript for floating
  aero-resize-dir = pkgs.writeShellScriptBin "aero-resize-dir" ''
    dir="$1"
    delta=50
    if ${isFloating}; then
      case "$dir" in
        h) exec ${lib.getExe resizefloating} -$delta 0 ;;
        l) exec ${lib.getExe resizefloating} $delta 0 ;;
        k) exec ${lib.getExe resizefloating} 0 -$delta ;;
        j) exec ${lib.getExe resizefloating} 0 $delta ;;
      esac
    fi
    case "$dir" in
      h) ${aerospaceBin} resize width -$delta ;;
      l) ${aerospaceBin} resize width $delta ;;
      k) ${aerospaceBin} resize height -$delta ;;
      j) ${aerospaceBin} resize height $delta ;;
    esac
  '';
  # skhd special c - re-grid floating window only
  center-if-floating = pkgs.writeShellScriptBin "center-if-floating" ''
    if ${isFloating}; then
      exec ${lib.getExe centerfloating}
    fi
  '';
  # skhd special minus/equal - keyboard backlight steps
  kblight-step = pkgs.writeShellScriptBin "kblight-step" ''
    step=0.1
    cur=$(${kblight} get)
    case "$1" in
      up)   val=$(echo "$cur $step" | awk '{print $1 + $2}') ;;
      down) val=$(echo "$cur $step" | awk '{print $1 - $2}') ;;
      *)    exit 1 ;;
    esac
    ${kblight} "$val"
  '';
in
{
  programs.aerospace.settings.mode.main.binding = {
    # floating move via arrows - aerospace extra, skhd doesn't use arrows
    "${mod}-shift-left" = "exec-and-forget ${lib.getExe movefloating} -100 0";
    "${mod}-shift-right" = "exec-and-forget ${lib.getExe movefloating} 100 0";
    "${mod}-shift-up" = "exec-and-forget ${lib.getExe movefloating} 0 -100";
    "${mod}-shift-down" = "exec-and-forget ${lib.getExe movefloating} 0 100";
  };
  programs.aerospace.settings.mode.service.binding = {
    # skhd special hjkl - nudge floating window 40px
    h = "exec-and-forget ${lib.getExe float-move} -40 0";
    l = "exec-and-forget ${lib.getExe float-move} 40 0";
    j = "exec-and-forget ${lib.getExe float-move} 0 40";
    k = "exec-and-forget ${lib.getExe float-move} 0 -40";

    # skhd special mod+hjkl - resize (tiled native, floating osascript)
    "${mod}-h" = "exec-and-forget ${lib.getExe aero-resize-dir} h";
    "${mod}-l" = "exec-and-forget ${lib.getExe aero-resize-dir} l";
    "${mod}-k" = "exec-and-forget ${lib.getExe aero-resize-dir} k";
    "${mod}-j" = "exec-and-forget ${lib.getExe aero-resize-dir} j";

    # skhd special minus/equal - keyboard backlight
    minus = "exec-and-forget ${lib.getExe kblight-step} down";
    equal = "exec-and-forget ${lib.getExe kblight-step} up";

    # skhd special c - re-grid floating window; shift+c - warp cursor
    c = "exec-and-forget ${lib.getExe center-if-floating}";
    "shift-c" = "move-mouse window-force-center";
  };
}
