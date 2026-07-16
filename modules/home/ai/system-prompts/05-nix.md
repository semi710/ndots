## Nix

This system is NixOS with Home Manager. All packages are managed via flakes.

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

Prefer `nix run nixpkgs#<pkg>` for one-off commands. This system already has `nix` configured with flakes and the `nixos` MCP server available for package lookups.
