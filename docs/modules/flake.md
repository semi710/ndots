# Flake Modules

Flake-level modules live in `modules/flake/`. These configure nix itself (the package, gc, registry, caches) and are shared across NixOS, Darwin, and standalone home-manager.

## Available Modules

| Module | Flake output | Description |
|---|---|---|
| [nix](#nix) | `flakeModules.nix` | Nix settings: latest nix, GC, registry, substituters |

## nix

Auto-imported directory (`modules/flake/nix/`). Exposed as `flake.flakeModules.nix`, imported by the NixOS `default.nix`, Darwin `default.nix`, and the `home-only.nix` home module.

### nix.nix

Core nix daemon configuration:

| Setting | Value | Purpose |
|---|---|---|
| `nix.package` | `nixVersions.latest` (forced) | Always use latest nix |
| `nix.gc.automatic` | `true` | Auto GC |
| `nix.gc.options` | `--delete-older-than 30d` | Keep 30 days |
| `nix.nixPath` | nixpkgs + nixpkgs-stable | Enables `nix-shell -p` |
| `nix.registry` | nixpkgs + nixpkgs-stable pinned | `nix shell` uses pinned flakes |
| `nix.settings.warn-dirty` | `false` | No warning on dirty git |
| `nix.settings.flake-registry` | empty | Nullify registry for purity |
| `nix.settings.trusted-users` | `@wheel` (Linux) | Trust wheel group |

Darwin-specific: `extra-platforms = "aarch64-darwin x86_64-darwin"` (Rosetta).

### caches.nix

Binary cache configuration. Sets substituters + trusted keys for faster builds:

| Cache | Key |
|---|---|
| `cache.nixos.asia/juspay` | juspay |
| `nix-community.cachix.org` | nix-community |
| `cache.nixos.org` | hydra.nixos.org |
| `cache.nixos.asia/oss` | oss |
| `nvix.cachix.org` | nvix |
| `hyprland.cachix.org` | hyprland |
| `attic.xuyh0120.win/lantian` | lantian |
| `cache.numtide.com` | numtide |

**Usage:**

These are imported automatically when you import `nixosModules.default` or `darwinModules.default`. For standalone home-manager, use `homeModules.home-only`.

```nix
{ flake, ... }: {
  imports = [ flake.flakeModules.nix ];
}
```

!!! tip "Adding a cache"
    Add to both `substituters` and `trusted-public-keys` lists in `modules/flake/nix/caches.nix`. The overlay already sets `trusted-substituters` to match.
