{
  pkgs,
  lib,
  config,
  ...
}:
let
  # mirrors skhd's hyper chord so gestures are identical in yabai mode
  mod = "cmd-alt-ctrl";
  aerospaceFocusCmd = lib.getExe pkgs.putils.aerospace-focus-fzf;
  kittenDmenuFocusCmd = "kitten panel --single-instance --instance-group dmenu --start-as-hidden --layer=top --edge=bottom -o cursor_trail=0 -o background_opacity=0.4 --focus-policy=exclusive --lines=20 ${aerospaceFocusCmd}";
  # toggle-app falls back to pgrep+osascript when yabai isn't running
  toggle-app = lib.getExe pkgs.putils.yabai-toggle-app;
  toggle-kitty = pkgs.writeShellScriptBin "toggle-kitty" ''
    exec ${toggle-app} --process "kitty.app/Contents/MacOS/kitty" kitty
  '';
  toggle-zen = pkgs.writeShellScriptBin "toggle-zen" ''
    exec ${toggle-app} "Zen Browser (Beta)"
  '';
  toggle-slack = pkgs.writeShellScriptBin "toggle-slack" ''
    osascript -e 'if application "Slack" is frontmost then' -e 'tell application "Slack" to hide' -e 'else' -e 'tell application "Slack" to activate' -e 'end if'
  '';
  specialOn = "exec-and-forget open -g hammerspoon://skhd-special-on";
  specialOff = "exec-and-forget open -g hammerspoon://skhd-special-off";
in
{
  programs.aerospace.settings = {
    exec.env-vars = {
      PATH = "/etc/profiles/per-user/${config.home.username}/bin:\${PATH}";
    };
  };
  programs.aerospace.settings.mode = {
    main.binding = {
      # skhd mod+grave enters special; port's old chord kept as alias
      "${mod}-backtick" = [
        "mode service"
        specialOn
      ];
      "${mod}-shift-semicolon" = [
        "mode service"
        specialOn
      ];
      "${mod}-shift-r" = "mode resize";

      "${mod}-q" = "close";

      # layouts - skhd mod+m (bsp<->stack), mod+shift+m (fullscreen)
      "${mod}-m" = "layout accordion tiles horizontal";
      "${mod}-shift-m" = "fullscreen toggle";
      "${mod}-shift-slash" = "layout accordion tiles horizontal";

      # skhd mod+comma - fzf picker: enter = focus, space = grab to current workspace
      "${mod}-comma" = "exec-and-forget ${kittenDmenuFocusCmd}";
      "${mod}-slash" = "exec-and-forget ${kittenDmenuFocusCmd}";

      # app toggles - skhd mod+enter/b/s, mod+shift+s
      "${mod}-enter" = "exec-and-forget ${lib.getExe toggle-kitty}";
      "${mod}-b" = "exec-and-forget ${lib.getExe toggle-zen}";
      "${mod}-s" = "exec-and-forget ${lib.getExe toggle-slack}";
      "${mod}-shift-s" = "exec-and-forget open -b com.apple.ScreenSaver.Engine";

      # Focus window - skhd mod+hjkl
      "${mod}-h" = [
        "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors left"
        "move-mouse window-lazy-center"
      ];
      "${mod}-j" = [
        "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors down"
        "move-mouse window-lazy-center"
      ];
      "${mod}-k" = [
        "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors up"
        "move-mouse window-lazy-center"
      ];
      "${mod}-l" = [
        "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors right"
        "move-mouse window-lazy-center"
      ];

      # Move window - skhd mod+shift+hjkl
      "${mod}-shift-h" = "move left";
      "${mod}-shift-j" = "move down";
      "${mod}-shift-k" = "move up";
      "${mod}-shift-l" = "move right";

      # Monitors - skhd mod+space (cycle display), mod+shift+space (move window)
      "${mod}-space" = "focus-monitor --wrap-around next";
      "${mod}-shift-space" = "move-node-to-monitor --wrap-around --focus-follows-window next";

      cmd-h = [ ]; # Disable "hide application"

      # workspaces - skhd mod+1..0, n/p, shift variants
      "${mod}-1" = "workspace 1";
      "${mod}-2" = "workspace 2";
      "${mod}-3" = "workspace 3";
      "${mod}-4" = "workspace 4";
      "${mod}-5" = "workspace 5";
      "${mod}-6" = "workspace 6";
      "${mod}-7" = "workspace 7";
      "${mod}-8" = "workspace 8";
      "${mod}-9" = "workspace 9";
      "${mod}-0" = "workspace 10";

      "${mod}-n" = "workspace next";
      "${mod}-p" = "workspace prev";

      "${mod}-shift-n" = "move-node-to-workspace --wrap-around next --focus-follows-window";
      "${mod}-shift-p" = "move-node-to-workspace --wrap-around prev --focus-follows-window";

      "${mod}-shift-1" = "move-node-to-workspace --focus-follows-window 1";
      "${mod}-shift-2" = "move-node-to-workspace --focus-follows-window 2";
      "${mod}-shift-3" = "move-node-to-workspace --focus-follows-window 3";
      "${mod}-shift-4" = "move-node-to-workspace --focus-follows-window 4";
      "${mod}-shift-5" = "move-node-to-workspace --focus-follows-window 5";
      "${mod}-shift-6" = "move-node-to-workspace --focus-follows-window 6";
      "${mod}-shift-7" = "move-node-to-workspace --focus-follows-window 7";
      "${mod}-shift-8" = "move-node-to-workspace --focus-follows-window 8";
      "${mod}-shift-9" = "move-node-to-workspace --focus-follows-window 9";
      "${mod}-shift-0" = "move-node-to-workspace --focus-follows-window 10";

      # skhd mod+shift+f (float toggle), mod+c (comms), mod+o (recent-ish)
      "${mod}-shift-f" = "layout floating tiling";
      "${mod}-o" = "workspace-back-and-forth";
      "${mod}-c" = "workspace Comms";
      "${mod}-shift-c" = "move-node-to-workspace --focus-follows-window Comms";
      "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

      # aerospace extras with no skhd counterpart
      "${mod}-left" = "join-with left";
      "${mod}-down" = "join-with down";
      "${mod}-up" = "join-with up";
      "${mod}-right" = "join-with right";
      "${mod}-backspace" = "close-all-windows-but-current";
      "${mod}-minus" = "resize smart -50";
      "${mod}-equal" = "resize smart +50";
      "${mod}-quote" = "move-node-to-workspace .scratchpad";
    };
    resize.binding = {
      h = "resize width -50";
      j = "resize height +50";
      k = "resize height -50";
      l = "resize width +50";
      enter = "mode main";
      esc = "mode main";
    };
    # plays the role of skhd's special mode
    service.binding = {
      # exits - skhd: escape/return/q/grave
      esc = [
        specialOff
        "mode main"
      ];
      enter = [
        specialOff
        "mode main"
      ];
      q = [
        specialOff
        "mode main"
      ];
      "${mod}-backtick" = [
        specialOff
        "mode main"
      ];
      "${mod}-shift-semicolon" = [
        specialOff
        "mode main"
      ];
      # skhd auto-reloads config; aerospace needs an explicit binding
      r = [
        "reload-config"
        "mode main"
      ];
      e = [ "enable toggle" ];
      # skhd special mod+r = space-reset
      "${mod}-r" = [
        "flatten-workspace-tree"
        "mode main"
      ];
      f = [
        "flatten-workspace-tree"
        "mode main"
      ];
      # skhd special shift+h = hammerspoon reload
      "shift-h" = "exec-and-forget open -g hammerspoon://hs-reload";
      # skhd special shift+space = space-move-display
      "shift-space" = "move-workspace-to-monitor --wrap-around next";
      # skhd special shift+minus/equal = resize smaller/bigger
      "shift-minus" = "resize smart -50";
      "shift-equal" = "resize smart +50";
      # port extras: manual tree surgery
      "${mod}-shift-h" = [
        "join-with left"
        "mode main"
      ];
      "${mod}-shift-j" = [
        "join-with down"
        "mode main"
      ];
      "${mod}-shift-k" = [
        "join-with up"
        "mode main"
      ];
      "${mod}-shift-l" = [
        "join-with right"
        "mode main"
      ];
    };
  };
}
