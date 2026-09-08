{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  combinedSystemPrompt = import ./combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./opencode/skills.nix { inherit inputs lib; };
in
{
  home.sessionVariables = {
    # vim-motions-pi: two-key escape sequence (e.g. jk, jj)
    VIM_MOTION_PI_ESCAPE_SEQUENCE = "jk";
    # vim-motions-pi: yank syncs to the system clipboard (default is "off",
    # which silently disables the command below)
    VIM_MOTION_PI_CLIPBOARD = "yank";
    # vim-motions-pi: custom clipboard command (OSC 52 via copy tool)
    VIM_MOTION_PI_CLIPBOARD_COMMAND = lib.getExe pkgs.copy;
  };

  # same skill set as opencode, minus ponytail (pi loads it from its package)
  home.file = skillsMod.piFiles;

  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.llm-agents.pi;
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.copy # clipboard tool for vim-motions-pi
    ];
    settings = {
      # same model as opencode's default (litellm/glm-latest on the juspay grid)
      defaultProvider = "juspay";
      defaultModel = "glm-latest";
      defaultThinkingLevel = "medium";
      theme = "dark";
      packages = [
        "npm:@termdraw/pi"
        "npm:pi-mcp-adapter"
        "${inputs.vim-motions-pi}"
        "git:github.com/DietrichGebert/ponytail"
      ];
    };
    # ~/.pi/agent/AGENTS.md - same content as opencode's AGENTS.md
    context = combinedSystemPrompt;
  };

}
