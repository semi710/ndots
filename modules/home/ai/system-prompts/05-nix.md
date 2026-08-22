## Nix

This system is NixOS with Home Manager. All packages are managed via flakes.

### Testing changes to flake inputs
When modifying a flake input repo (e.g. `utils`, `nvix`), NEVER push to remote or bump the flake lock to a remote commit until the user explicitly approves. Instead:

1. Make the edit in the local checkout (e.g. `~/work/utils`).
2. Point the consuming flake at the local path: `inputs.utils.url = "path:../utils";` temporarily, or use `nix flake lock --override-input utils ../utils`.
3. Build and test locally: `nix build`, `nix run`, or `darwin-rebuild switch` / `nixos-rebuild switch`.
4. Only after the user approves: push the input repo, then `nix flake lock --update-input <name>` to pin the remote commit.

### Missing package or tool
If you need a CLI tool, library, or binary that is not installed, do not ask the user to install it manually. Use `nix run` to execute it ad-hoc, or `nix-shell -p` to get a shell with it:

```bash
# Run a package without installing
nix run nixpkgs#<package>

# Drop into a shell with a package available
nix-shell -p <package>

# Search for a package name
nix search nixpkgs <query>
```

Prefer `nix run nixpkgs#<pkg>` for one-off commands. Never use `nix profile add` or `nix profile install` - it pollutes the user profile and breaks reproducibility. Use `nix-shell -p` for temporary shells instead. This system already has `nix` configured with flakes and the `nixos` MCP server available for package lookups.
