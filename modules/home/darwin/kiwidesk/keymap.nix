# The default keymap + settings block, as a module: contributes
# `kiwidesk.initLuaBase`, which default.nix layers under the user's
# initLua and above the local.lua bridge.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.kiwidesk;
  # The one chord the whole map is built on: ctrl+opt+cmd, produced
  # by the Hyperkey app (tap caps = esc, hold caps = this chord).
  # KiwiDesk's own hyper key is NOT used - it would take caps over
  # completely (hidutil -> F18) and kill tap-esc.
  mod = "ctrl+opt+cmd";

  # one chord -> one Lua line; body is any Lua expression/statement
  bind = chord: body: ''KiwiDesk.bind("${chord}", function() ${body} end)'';
  # a { key = body; } table -> one Lua line each, all under one chord prefix
  binds =
    prefix: entries:
    lib.concatStringsSep "
" (lib.mapAttrsToList (k: v: bind "${prefix}${k}" v) entries);
  # move the focused window to the next/prev Space on the focused
  # screen: no relative-space verb exists, so compute the neighbour
  # from get_state and call move_to_space_and_follow (jq negative
  # indices wrap prev from the first Space)
  moveSpace =
    step:
    ''KiwiDesk.exec([[sh -c 'k=${config.programs.kiwidesk.package}/bin/kiwidesk; j=${lib.getExe pkgs.jq}; s=$($k get_state) && w=$($k list_windows) && c=$(printf "%s" "$w" | $j -r "([.[] | select(.focused)][0].space_id) // empty") && [ -n "$c" ] || c=$(printf "%s" "$s" | $j -r .active_space) && n=$(printf "%s" "$s" | $j -r --arg c "$c" ".spaces | map(.id) as \$i | (\$i | index(\$c)) as \$x | \$i[((\$x ${step}) % (\$i|length))]") && $k move_to_space_and_follow "$n"']])'';
  # 1..9: <verb>(n) under mod (+extra), one line per digit
  digitBinds =
    verb: extra:
    lib.concatStringsSep "
" (
      builtins.genList (
        i:
        let
          n = toString (i + 1);
        in
        bind "${mod}+${extra}${n}" "KiwiDesk.${verb}(${n})"
      ) 9
    );

  keymap = # lua
    ''
      -- m toggles the two workhorse layouts; other layouts ride
      -- the mod+s picker panel
      KiwiDesk.set_mode_cycle({ "bsp", "monocle" })
      KiwiDesk.set_mode_cue(false)
      -- Space switches: instant, nothing drawn over the windows
      KiwiDesk.set_space_transition("none")

      -- thinner than the default 5pt focus border
      border.set_width(2)

      -- yabai parity: hover-focus + pointer-warp
      mouse.set_hover_focus(true)
      mouse.set_follows_focus(true)

      -- pocket holds several windows; drag&drop on
      pocket.set_capacity("several")
      drag.set_drop_zone_enabled(true)
      drag.set_ghost_enabled(true)

      -- panels: Liquid Glass on, untinted; bars: glass off (flat fill)
      KiwiDesk.set_shortcut_panel_liquid_glass(true)
      kiwishelf.set_tint_hub_and_plates(false)
      -- glass ON for the bars: off renders them fully transparent on
      -- this macOS, not the flat fill the docs describe
      kiwishelf.set_liquid_glass(true)
      -- KiwiHub selection keys (j/k every side, h/l on the View side)
      kiwihub.set_key("down", "ctrl+j")
      kiwihub.set_key("up", "ctrl+k")
      kiwihub.set_key("down", "ctrl+n")
      kiwihub.set_key("up", "ctrl+p")
      kiwihub.set_key("left", "ctrl+h")
      kiwihub.set_key("right", "ctrl+l")

      -- Space Bar: bottom edge, centered, flush; App Bar off
      space_bar.set_edge("bottom")
      kiwishelf.set_alignment("center")
      kiwishelf.set_outer_margin(0)
      monocle.set_app_bar_visibility("hidden")
      scroll.set_app_bar_visibility("hidden")

      -- float rules: yabai era's unmanaged apps by bundle id
      float_rules = {
        "com.apple.systempreferences",
        "com.apple.calculator",
        "com.apple.finder",
        "com.apple.mail",
        "com.apple.MobileSMS",
        "com.apple.FaceTime",
        "com.apple.iCal",
        "com.apple.weather",
        "com.apple.Passwords",
        "com.apple.ScreenSharing",
        "com.apple.ScreenContinuity",
        "io.mpv",
        "net.whatsapp.WhatsApp",
        "com.sertacozercan.Kaset",
        "com.openai.chat",
        "ch.protonvpn.mac",
        "com.objective-see.lulu",
        "io.tailscale.ipn.macos",
        "com.sindresorhus.Gifski",
        "com.dwarvesv.minimalbar",
        "org.pqrs.Karabiner-Elements",
      }

      -- mod chord: focus, move, launch, spaces, bars, pockets, layers
      ${binds "${mod}+" {
        h = ''KiwiDesk.focus("left")'';
        j = ''KiwiDesk.focus("down")'';
        k = ''KiwiDesk.focus("up")'';
        l = ''KiwiDesk.focus("right")'';
        q = "KiwiDesk.close_window()";
        n = "KiwiDesk.focus_space_next()";
        p = "KiwiDesk.focus_space_previous()";
        "0" = "KiwiDesk.focus_space_back()";
        space = "KiwiDesk.focus_display_last()";
        m = "KiwiDesk.cycle_mode()";
        s = ''kiwihub.show("view")'';
        o = ''kiwihub.show("windows")'';
        slash = ''kiwihub.show("windows")'';
        c = ''KiwiDesk.focus_space("comms")'';
        apostrophe = "KiwiDesk.pocket()";
        w = "space_bar.toggle_reveal()";
        b = "app_bar.toggle_reveal()";
        "return" = ''KiwiDesk.focus_or_spawn("net.kovidgoyal.kitty")'';
      }}

      -- mod+shift: swap, window state, comms move, pocket add
      ${binds "${mod}+shift+" {
        h = ''KiwiDesk.swap("left")'';
        j = ''KiwiDesk.swap("down")'';
        k = ''KiwiDesk.swap("up")'';
        l = ''KiwiDesk.swap("right")'';
        f = "KiwiDesk.toggle_floating()";
        a = "KiwiDesk.toggle_sticky()";
        m = "KiwiDesk.toggle_maximized()";
        v = "kiwivision.toggle()";
        c = ''KiwiDesk.move_to_space_and_follow("comms")'';
        apostrophe = "KiwiDesk.toggle_pocket_window()";
        n = moveSpace " + 1";
        p = moveSpace " - 1";
      }}

      -- special layer entry: switch_layer + the floating pill
      -- (bottom right; the Space Bar item stays, no way to hide it)
      KiwiDesk.bind("${mod}+semicolon", function()
        KiwiDesk.switch_layer("special")
        KiwiDesk.exec("open -g 'hammerspoon://kw-layer-on?label=SPECIAL'")
      end)

      -- 1..9 focus a Space; shift+1..9 move the window and follow
      -- (keymap.nix tables above are joined with these)
      ${digitBinds "focus_space" ""}
      ${digitBinds "move_to_space_and_follow" "shift+"}

      -- special layer (mod+;): hjkl resize, shift+hjkl nudge (hs),
      -- c center (hs), g/b bars, esc/return exit
      KiwiDesk.define_layer("special", {
        ["h"] = function() KiwiDesk.resize("x", -50) end,
        ["l"] = function() KiwiDesk.resize("x", 50) end,
        ["j"] = function() KiwiDesk.resize("y", -50) end,
        ["k"] = function() KiwiDesk.resize("y", 50) end,
        ["shift+h"] = function()
          KiwiDesk.exec("open -g 'hammerspoon://kw-nudge?dx=-40&dy=0'")
        end,
        ["shift+l"] = function()
          KiwiDesk.exec("open -g 'hammerspoon://kw-nudge?dx=40&dy=0'")
        end,
        ["shift+j"] = function()
          KiwiDesk.exec("open -g 'hammerspoon://kw-nudge?dx=0&dy=40'")
        end,
        ["shift+k"] = function()
          KiwiDesk.exec("open -g 'hammerspoon://kw-nudge?dx=0&dy=-40'")
        end,
        ["g"] = function() space_bar.toggle_reveal() end,
        ["b"] = function() app_bar.toggle_reveal() end,
        ["c"] = function()
          KiwiDesk.exec("open -g hammerspoon://kw-center")
        end,
        ["return"] = function()
          KiwiDesk.switch_layer("default")
          KiwiDesk.exec("open -g hammerspoon://kw-layer-off")
        end,
        ["escape"] = function()
          KiwiDesk.switch_layer("default")
          KiwiDesk.exec("open -g hammerspoon://kw-layer-off")
        end,
      })
    '';

in
{
  options.kiwidesk = {
    defaultKeymap = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        The yabai/skhd-parity keymap: ctrl+opt+cmd chords (caps
        via the Hyperkey app), hjkl focus, shift+hjkl swap, 1-9
        spaces, n/p cycle, 0 history-back, space toggles displays,
        q closes, m cycles bsp/monocle, s the view picker, o the
        window switcher, ; the special layer (resize, nudge,
        center), shift+f/a/m/v float/sticky/maximize/vision, g/b
        the bars, ' pocket, c the comms space, / the window
        switcher. Also sets a 2pt focus border and the float rules.
      '';
    };

    initLuaBase = lib.mkOption {
      type = lib.types.lines;
      default = "";
      internal = true;
      description = "Lua this module ships; default.nix layers it.";
    };
  };

  config.kiwidesk.initLuaBase = lib.mkIf cfg.defaultKeymap keymap;
}
