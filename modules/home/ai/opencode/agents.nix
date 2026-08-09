# Opencode agent definitions. Add a new agent block here, or drop a new
# .nix sibling - opencode/default.nix auto-imports all siblings except
# the helpers (skills.nix).
{ ... }:
{
  programs.opencode.settings = {
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
