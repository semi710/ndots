# Opencode agent definitions. Add a new agent block here, or drop a new
# .nix sibling - opencode/default.nix auto-imports all siblings except
# the helpers (skills.nix, registry.nix).
{
  inputs,
  lib,
  ...
}:
let
  skillsMod = import ./skills.nix { inherit inputs lib; };
in
{
  programs.opencode.settings = {
    default_agent = "OpenAgent";
    agent = {
      # Registry's openagent.md is the base (prompt, tools, permissions).
      # Our rules live in AGENTS.md (global, applied on top of every agent).
      # Skills survive the merge - they add to whatever the registry provides.
      OpenAgent.skills = skillsMod.skills;
      explore = {
        mode = "subagent";
        model = "litellm/open-fast";
      };
    };
  };
}
