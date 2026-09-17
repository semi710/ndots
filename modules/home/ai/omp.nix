{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  combinedSystemPrompt = import ./combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./opencode/skills.nix { inherit inputs lib; };
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
      modelRoles.default = "juspay/glm-latest";
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
    };
  };

  home.file = skillsMod.ompFiles // {
    # same content as opencode's AGENTS.md - omp loads it as user-level context
    ".omp/agent/AGENTS.md".text = combinedSystemPrompt;
  };
}
