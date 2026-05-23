{ pkgs, lib, ... }:
let
  mod = "cmd + alt + ctrl";
  yabai-restart = pkgs.writeShellScriptBin "yabai-restart" ''
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

      ${mod} - return : ${lib.getExe pkgs.putils.yabai-toggle-app} --process .kitty-wrapped "kitty"
      ${mod} - b : ${lib.getExe pkgs.putils.yabai-toggle-app} "Zen Browser (Beta)"
      ${mod} - s : ${lib.getExe pkgs.putils.yabai-toggle-app} "Slack"
      ${mod} + shift - s : open -b com.apple.ScreenSaver.Engine

      ${mod} - h : ${lib.getExe pkgs.putils.yabai-cycle-focus} west
      ${mod} - j : ${lib.getExe pkgs.putils.yabai-cycle-focus} south
      ${mod} - k : ${lib.getExe pkgs.putils.yabai-cycle-focus} north
      ${mod} - l : ${lib.getExe pkgs.putils.yabai-cycle-focus} east

      ${mod} - q : yabai -m window --close

      ${mod} + shift - h : ${lib.getExe pkgs.putils.yabai-cycle-move} west
      ${mod} + shift - j : ${lib.getExe pkgs.putils.yabai-cycle-move} south
      ${mod} + shift - k : ${lib.getExe pkgs.putils.yabai-cycle-move} north
      ${mod} + shift - l : ${lib.getExe pkgs.putils.yabai-cycle-move} east

      ${mod} - n : ${lib.getExe pkgs.putils.yabai-space-cycle} next
      ${mod} - p : ${lib.getExe pkgs.putils.yabai-space-cycle} prev

      ${mod} + shift - 0x2C : ${lib.getExe pkgs.putils.yabai-get-window}
      ${mod} - 0x2C : ${lib.getExe pkgs.putils.yabai-focus-window}

      ${mod} + shift - n : \
        yabai -m window --space next --focus \
          || yabai -m window --space prev --focus \
          || (yabai -m space --create && yabai -m window --space next --focus)
      ${mod} + shift - p : yabai -m window --space prev --focus || yabai -m window --space next --focus

      ${mod} - space : ${lib.getExe pkgs.putils.yabai-cycle-display} next
      ${mod} + shift - space : ${lib.getExe pkgs.putils.yabai-cycle-move-display} next

      ${mod} + shift - f : yabai -m window --toggle float --grid 8:8:1:1:6:6

      special < r : yabai -m space --rotate 90 ; default
      special < x : yabai -m window --toggle split ; default
      special < b : yabai -m space --balance ; default

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

      special < h : yabai -m window --resize right:-20:0 2> /dev/null || yabai -m window --resize left:20:0 2> /dev/null
      special < j : yabai -m window --resize bottom:0:20 2> /dev/null || yabai -m window --resize top:0:-20 2> /dev/null
      special < k : yabai -m window --resize bottom:0:-20 2> /dev/null || yabai -m window --resize top:0:20 2> /dev/null
      special < l : yabai -m window --resize right:20:0 2> /dev/null || yabai -m window --resize left:-20:0 2> /dev/null

      special < shift - 0x2B : ${lib.getExe pkgs.putils.yabai-resize} smaller
      special < shift - 0x2F : ${lib.getExe pkgs.putils.yabai-resize} bigger

      special < c : [ "$(yabai -m query --windows --window | jq '.["is-floating"]')" = "true" ] && yabai -m window --grid 8:8:1:1:6:6 ; default

      special < shift - c : ${lib.getExe pkgs.putils.yabai-warp-cursor} ; default

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
