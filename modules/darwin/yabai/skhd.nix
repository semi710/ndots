{ pkgs, lib, ... }:
let
  mod = "cmd + alt + ctrl";
  spaceCycleNext =
    pkgs.writeShellScriptBin "space-cycle-next" # sh
      ''
        info=$(yabai -m query --spaces --display)
        last=$(echo $info | jq '.[-1]."has-focus"')

        if [[ $last == "false" ]]; then
            yabai -m space --focus next
        else
            yabai -m space --focus $(echo $info | jq '.[0].index')
        fi
      '';

  spaceCyclePrev =
    pkgs.writeShellScriptBin "space-cycle-prev" # sh
      ''
        info=$(yabai -m query --spaces --display)
        first=$(echo $info | jq '.[0]."has-focus"')

        if [[ $first == "false" ]]; then
            yabai -m space --focus prev
        else
            yabai -m space --focus $(echo $info | jq '.[-1].index')
        fi
      '';

  cycleDisplay =
    pkgs.writeShellScriptBin "cycle-display" # sh
      ''
        dir="''${1:-next}"
        displays=$(yabai -m query --displays | jq 'sort_by(.index)')
        count=$(echo "$displays" | jq 'length')

        cur_idx=$(yabai -m query --displays --display | jq -r '.index')

        case "$dir" in
          next)
            next_idx=$(( (cur_idx % count) + 1 ))
            ;;
          prev)
            next_idx=$(( ( (cur_idx - 2 + count) % count ) + 1 ))
            ;;
          *)
            next_idx=$cur_idx
            ;;
        esac

        yabai -m display --focus "$next_idx"
      '';

  cycleMoveDisplay =
    pkgs.writeShellScriptBin "cycle-move-display" # sh
      ''
        dir="''${1:-next}"
        displays=$(yabai -m query --displays | jq 'sort_by(.index)')
        count=$(echo "$displays" | jq 'length')

        cur_idx=$(yabai -m query --displays --display | jq -r '.index')

        case "$dir" in
          next)
            next_idx=$(( (cur_idx % count) + 1 ))
            ;;
          prev)
            next_idx=$(( ( (cur_idx - 2 + count) % count ) + 1 ))
            ;;
          *)
            next_idx=$cur_idx
            ;;
        esac

        # Move the focused window to the target display
        yabai -m window --display "$next_idx"

        # Then focus that display
        yabai -m display --focus "$next_idx";
      '';

  cycleFocus =
    pkgs.writeShellScriptBin "cycle-focus" # sh
      ''
        dir="''${1:-next}"

        # Are we in a stack? (check the focused window)
        cur_json="$(yabai -m query --windows --window)"
        cur_idx="$(printf '%s\n' "$cur_json" | jq -r '."stack-index"')"
        is_floating="$(printf '%s\n' "$cur_json" | jq -r '."is-floating"')"

        if [ "$cur_idx" -gt 0 ] 2>/dev/null; then
          case "$dir" in
            east|south|next)
              last_idx="$(yabai -m query --windows --window stack.last | jq -r '."stack-index"')"
              if [ "$cur_idx" -eq "$last_idx" ]; then
                yabai -m window --focus stack.first
              else
                yabai -m window --focus stack.next
              fi
              ;;
            west|north|prev)
              first_idx="$(yabai -m query --windows --window stack.first | jq -r '."stack-index"')"
              if [ "$cur_idx" -eq "$first_idx" ]; then
                yabai -m window --focus stack.last
              else
                yabai -m window --focus stack.prev
              fi
              ;;
            *)
              yabai -m window --focus stack.next
              ;;
          esac
        elif [ "$is_floating" = "true" ]; then
          # Directional focus doesn't apply to floating windows in BSP.
          # Snap back to the most recently focused window.
          yabai -m window --focus recent
        else
          # Not in a stack: fall back to directional focus
          case "$dir" in
            east|west|north|south) yabai -m window --focus "$dir" ;;
            next) yabai -m window --focus east || yabai -m window --focus south || yabai -m window --focus west || yabai -m window --focus north ;;
            prev) yabai -m window --focus west || yabai -m window --focus north || yabai -m window --focus east || yabai -m window --focus south ;;
            *)    yabai -m window --focus "$dir" ;;
          esac
        fi
      '';

  focusWindow =
    pkgs.writeShellScriptBin "focus-window" # sh
      ''
        choice=$(yabai -m query --windows \
          | jq -r '.[] | select(.app | endswith("-wrapped") | not) | "\(.id)|\(.app): \(.title)"' \
          | awk -F'|' '{print $2 "\t" $1}' \
          | ${lib.getExe pkgs.choose-gui} -n 15 -w 120 -f "Monaspace Radon Var" -s 26 -c FF9800 -b a9a9a9 -p "󰖰  Focus window:")

        id=$(echo "$choice" | awk '{print $NF}')
        app=$(echo "$choice" | awk -F':' '{print $1}')

        [ -n "$id" ] && yabai -m window --focus "$id" || open -a "$app"
      '';

  getWindow =
    pkgs.writeShellScriptBin "get-window" # sh
      ''
        choice=$(yabai -m query --windows \
          | jq -r '.[] | select(.app | endswith("-wrapped") | not) | "\(.id)|\(.app): \(.title)"' \
          | awk -F'|' '{print $2 "\t" $1}' \
          | ${lib.getExe pkgs.choose-gui} -n 15 -w 120 -f "Monaspace Radon Var" -s 26 -c FF9800 -b 1E1E1E -p "󰖰  Pull window:")

        id=$(echo "$choice" | awk '{print $NF}')
        app=$(echo "$choice" | awk -F':' '{print $1}')

        if [ -n "$id" ]; then
          current_space=$(yabai -m query --spaces --space | jq '.index')
          yabai -m window "$id" --space "$current_space" || open -a "$app"
        fi
      '';

  warpCursor =
    pkgs.writeShellScriptBin "warp-cursor" # sh
      ''
        yabai -m query --windows --window \
          | ${lib.getExe pkgs.jq} -r '.frame | "hs.mouse.absolutePosition({x=\(.x + .w/2), y=\(.y + .h/2)})"' \
          | xargs -I{} osascript -e 'tell application "Hammerspoon" to execute lua code "{}"'
      '';

  yabai-restart =
    pkgs.writeShellScriptBin "yabai-restart" # sh
      ''
        kill -9 $(pgrep -x yabai); kill -9 $(pgrep -x skhd); sudo yabai --load-sa
      '';
in
{
  environment.systemPackages = [
    pkgs.skhd-zig
    yabai-restart
  ];
  services.skhd = {
    enable = true;
    package = pkgs.skhd-zig;
    skhdConfig = ''
      :: default   : open -g hammerspoon://skhd-special-off
      :: special @ : open -g hammerspoon://skhd-special-on

      ${mod} - 0x29 ; special

      special < escape ; default
      special < return ; default
      special < 0x29   ; default
      special < q      ; default

      ${mod} - return : open -a "kitty"
      ${mod} - b : open -a "Zen Browser (Beta)"
      ${mod} - s : open -a "slack"
      ${mod} + shift - s : open -b com.apple.ScreenSaver.Engine

      ${mod} - h : ${lib.getExe cycleFocus} west
      ${mod} - j : ${lib.getExe cycleFocus} south
      ${mod} - k : ${lib.getExe cycleFocus} north
      ${mod} - l : ${lib.getExe cycleFocus} east

      ${mod} - q : yabai -m window --close

      # swap windows                       --swap (for swapping i like warp)
      # Move or Warp depending on floating state
      ${mod} + shift - h : if [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ]; then yabai -m window --move rel:-20:0; else yabai -m window --warp west; fi
      ${mod} + shift - j : if [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ]; then yabai -m window --move rel:0:20; else yabai -m window --warp south; fi
      ${mod} + shift - k : if [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ]; then yabai -m window --move rel:0:-20; else yabai -m window --warp north; fi
      ${mod} + shift - l : if [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ]; then yabai -m window --move rel:20:0; else yabai -m window --warp east; fi

      ${mod} - n : ${lib.getExe spaceCycleNext}
      ${mod} - p : ${lib.getExe spaceCyclePrev}

      ${mod} + shift - 0x2C : ${lib.getExe getWindow}
      ${mod} - 0x2C : ${lib.getExe focusWindow}


      ${mod} + shift - n : \
        yabai -m window --space next --focus \
          || yabai -m window --space prev --focus \
          || (yabai -m space --create && yabai -m window --space next --focus)
      ${mod} + shift - p : yabai -m window --space prev --focus || yabai -m window --space next --focus

      ${mod} - space : ${lib.getExe cycleDisplay} next
      ${mod} + shift - space : ${lib.getExe cycleMoveDisplay} next

      ${mod} + shift - f : yabai -m window --toggle float --grid 8:8:1:1:6:6

      ${mod} - r : yabai -m space --rotate 90

      ${mod} - x : yabai -m window --toggle split

      ${mod} - m : \
        case "$(yabai -m query --spaces --space | ${lib.getExe pkgs.jq} -r '.type')" in \
            bsp)   yabai -m space --layout stack ;; \
            stack) yabai -m space --layout bsp ;; \
        esac

      ${mod} + shift - m : yabai -m window --toggle native-fullscreen

      ${mod} + shift - a : yabai -m window --toggle sticky

      ${mod} - o : yabai -m window --focus recent

      ${mod} - c : yabai -m space --focus comms
      ${mod} + shift - c : yabai -m window --space comms --focus

      # Fallback edge needs OPPOSITE sign to preserve intent (moving the
      # opposite handle in the same direction grows/shrinks consistently).
      special < h : yabai -m window --resize right:-20:0 2> /dev/null || yabai -m window --resize left:20:0 2> /dev/null
      special < j : yabai -m window --resize bottom:0:20 2> /dev/null || yabai -m window --resize top:0:-20 2> /dev/null
      special < k : yabai -m window --resize bottom:0:-20 2> /dev/null || yabai -m window --resize top:0:20 2> /dev/null
      special < l : yabai -m window --resize right:20:0 2> /dev/null || yabai -m window --resize left:-20:0 2> /dev/null

      special < c : [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ] && yabai -m window --grid 8:8:1:1:6:6 ; default

      special < shift - c : ${lib.getExe warpCursor} ; default

      ${mod} - 1 : yabai -m space --focus 1
      ${mod} - 2 : yabai -m space --focus 2
      ${mod} - 3 : yabai -m space --focus 3
      ${mod} - 4 : yabai -m space --focus 4
      ${mod} - 5 : yabai -m space --focus 5
      ${mod} - 6 : yabai -m space --focus 6
      ${mod} - 7 : yabai -m space --focus 7
      ${mod} - 8 : yabai -m space --focus 8
      ${mod} - 9 : yabai -m space --focus 9

      ${mod} + shift - 1 : yabai -m window --space 1 --focus
      ${mod} + shift - 2 : yabai -m window --space 2 --focus
      ${mod} + shift - 3 : yabai -m window --space 3 --focus
      ${mod} + shift - 4 : yabai -m window --space 4 --focus
      ${mod} + shift - 5 : yabai -m window --space 5 --focus
      ${mod} + shift - 6 : yabai -m window --space 6 --focus
      ${mod} + shift - 7 : yabai -m window --space 7 --focus
      ${mod} + shift - 8 : yabai -m window --space 8 --focus
      ${mod} + shift - 9 : yabai -m window --space 9 --focus
    '';
  };
}
