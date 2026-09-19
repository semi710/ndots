{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  combinedSystemPrompt = import ../combined-system-prompt.nix { inherit lib; };
  skillsMod = import ../opencode/skills.nix { inherit inputs lib; };

  themes = import ./theme.nix {
    inherit lib;
    omp = inputs.omp;
    palette = config.ndots.ai.omp.base16Colors;
  };
in
{
  options.ndots.ai.omp.base16Colors = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      base00 = "181616";
      base01 = "282727";
      base02 = "393836";
      base03 = "625e5a";
      base04 = "737c73";
      base05 = "c5c9c5";
      base06 = "c8c093";
      base07 = "c5c9c5";
      base08 = "c4746e";
      base09 = "b6927b";
      base0A = "c4b28a";
      base0B = "8a9a7b";
      base0C = "8ea4a2";
      base0D = "8ba4b0";
      base0E = "a292a3";
      base0F = "b98d7b";
    };
    description = "Base16 palette (hex, no #) driving the ndots-dark omp theme; stylix hosts override with config.lib.stylix.colors";
  };

  imports = [ inputs.omp.homeManagerModules.default ];

  config = {
    # nix LSP - omp input auto-detects it from flake.nix root markers and wires
    # diagnostics/imports into edits. Other servers resolve from project bins/PATH.
    home.packages = [ pkgs.nil ];

    programs.omp = {
      enable = true;
      settings = {
        # same model as opencode's default (litellm/glm-latest on the juspay grid)
        modelRoles = {
          default = "juspay/glm-latest";
          # advisor/prewalk have no juspay model in their builtin fallback chains
          advisor = "juspay/claude-sonnet-4-6";
          smol = "juspay/glm-flash-experimental";
        };
        defaultThinkingLevel = "medium";
        # replaces vim-motions-pi; no jk escape, plain Escape only
        tui.vimMode = true;
        # pi-style status line: `π > INSERT > ⬢ model > 📁 path > ⑂ git ▶─ctx─`
        statusLine.preset = "default";
        # pi-style composer: framed horizontal rules, status line at bottom
        composer.shape = "pi";
        # skip the one-time setup wizard; nerd glyphs (Kitty font has them)
        setupVersion = 2;
        symbolPreset = "nerd";

        # local SQLite memory: recall/retain per project, no remote dependency
        memory.backend = "mnemopi";
        # post-stop lesson capture + managed skill minting
        autolearn.enabled = true;
        # second-opinion reviewer on stop; needs an explicit model (see modelRoles)
        advisor.enabled = true;
        # pre-arm the session with a repo map before the first prompt
        prewalk.enabled = true;

        # dark is derived from the base16 palette; light stays upstream
        theme.dark = "ndots-dark";
        theme.light = "ndots-light";
      };
    };

    home.file = skillsMod.ompFiles // {
      # same content as opencode's AGENTS.md - omp loads it as user-level context
      ".omp/agent/AGENTS.md".text = combinedSystemPrompt;

      # derived themes land where omp discovers custom themes by name
      ".omp/agent/themes/ndots-dark.json".text = builtins.toJSON themes.dark;
      ".omp/agent/themes/ndots-light.json".text = builtins.toJSON themes.light;

      # vim-style select navigation; alt-chords dodge type-to-search which eats plain j/k
      # (user bindings replace defaults, so the arrows must stay listed).
      # app.display.reset drops its default alt+l so tmux's alt+h/l -> Left/Right
      # translation stays consistent outside tmux too (display reset is unused).
      ".omp/agent/keybindings.yml".text = ''
        tui.select.up: ["up", "alt+k"]
        tui.select.down: ["down", "alt+j"]
        app.display.reset: []
      '';
    };
  };
}
