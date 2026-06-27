# Opencode agent definitions. Add a new agent block here, or drop a new
# .nix sibling - opencode/default.nix auto-imports all siblings except
# the helpers (skills.nix, registry.nix).
{
  inputs,
  lib,
  ...
}:
let
  combinedSystemPrompt = import ../combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./skills.nix { inherit inputs lib; };
in
{
  programs.opencode.settings = {
    default_agent = "OpenAgent";
    agent = {
      OpenAgent = {
        prompt = combinedSystemPrompt;
        skills = skillsMod.skills;
      };
      explore = {
        mode = "subagent";
        model = "litellm/open-fast";
      };
    };
  };
}
