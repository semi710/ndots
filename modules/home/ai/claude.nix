{
  lib,
  ...
}:
let
  combinedSystemPrompt = import ./combined-system-prompt.nix { inherit lib; };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      preferences.vimMode = true;
      model = "claude-opus-4-6";
      env.ENABLE_TOOL_SEARCH = true;
    };
  };

  home.file.".claude/CLAUDE.md".text = combinedSystemPrompt;
}
