{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  combinedSystemPrompt = import ./combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./opencode/skills.nix { inherit inputs lib; };

  # Derived themes: upstream colors + the unicode square-box context icon.
  # The nerd preset's icon.context is the Windows logo (\ue70f); overriding it
  # per-theme is the only supported symbol override path.
  mkTheme =
    name: base:
    lib.recursiveUpdate base {
      inherit name;
      symbols.overrides."icon.context" = "◫";
    };
  ndots-dark = mkTheme "ndots-dark" (
    builtins.fromJSON (
      builtins.readFile "${inputs.omp}/packages/coding-agent/src/modes/theme/defaults/titanium.json"
    )
  );
  ndots-light = mkTheme "ndots-light" (
    builtins.fromJSON (
      builtins.readFile "${inputs.omp}/packages/coding-agent/src/modes/theme/light.json"
    )
  );
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  # nix LSP - omp auto-detects it from flake.nix root markers and wires
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

      # derived from upstream titanium/light with the box context icon
      theme.dark = "ndots-dark";
      theme.light = "ndots-light";
    };
  };

  home.file = skillsMod.ompFiles // {
    # same content as opencode's AGENTS.md - omp loads it as user-level context
    ".omp/agent/AGENTS.md".text = combinedSystemPrompt;

    # derived themes land where omp discovers custom themes by name
    ".omp/agent/themes/ndots-dark.json".text = builtins.toJSON ndots-dark;
    ".omp/agent/themes/ndots-light.json".text = builtins.toJSON ndots-light;
  };
}
