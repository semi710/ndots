# Opencode agent definitions. Add a new agent block here, or drop a new
# .nix sibling - opencode/default.nix auto-imports all siblings except
# the helpers (skills.nix, registry.nix).
{ ... }:
{
  programs.opencode.settings = {
    # OmO plugin registers all agents (sisyphus, hephaestus, etc.).
    # Keep skills installed, but do not preload them into the primary agent
    # prompt. The plugin prepends agent.skills bodies to every new session.
    default_agent = "sisyphus";
    agent = {
      sisyphus = {
        prompt = ''
          Commit hygiene: NEVER set --author to yourself or add Co-authored-by trailers for the AI agent. Always commit as the repository's configured git identity. Never commit or push without explicit user approval.
        '';
      };
    };
  };
}
