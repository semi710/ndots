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
    # OmO plugin registers all agents (sisyphus, hephaestus, etc.).
    # We only add skills to the built-in agents here; the plugin's
    # config handler merges these on top of its own agent definitions.
    default_agent = "sisyphus";
    agent = {
      sisyphus.skills = skillsMod.skills;
    };
  };
}
