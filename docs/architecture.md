# Architecture

## Flake Structure

```
flake.nix
  └── nix-wire.mkFlake
        ├── perSystem         # devShells, treefmt, pre-commit
        └── nixosConfigurations  # auto-wired from hosts/nixos/*/
              └── each host dir → nixpkgs.lib.nixosSystem
                    ├── networking.hostName = <dir-name>  (auto-set)
                    ├── modules/nixos/*  (auto-imported via nix-wire)
                    └── home-manager (wired per-host)
```

## Auto-wiring

[nix-wire](https://github.com/semi710/nix-wire) auto-imports modules and host configs:

- `hosts/nixos/<name>/default.nix` → `nixosConfigurations.<name>`
- `modules/nixos/<name>/default.nix` → `nixosModules.<name>`
- `modules/home/<name>/default.nix` → `homeModules.<name>`
- `modules/darwin/<name>/default.nix` → `darwinModules.<name>`

Directories with a `default.nix` are auto-imported. `autoImportExcept` is used where files need exclusion.

## Module Layering

```
modules/
  nixos/
    default.nix          # base system (imports hardware, juspay, stylix)
    beszel.nix           # monitoring agent
    filebrowser.nix      # FileBrowser Quantum service
    virtualisation.nix   # docker (system+rootless) + podman
    tailscale.nix        # mesh VPN
    hardware/            # audio, bluetooth
    hyprland/             # window manager
    juspay/               # Juspay workspace config
  home/
    shell/               # zsh, tmux, fzf, starship, git
    editor/              # Helix, nvix (Neovim)
    ai/                  # opencode, claude, mcp, skills
    browser/             # Zen browser
    syncthing.nix        # file sync
    ...
  darwin/
    yabai/               # tiling WM + skhd
    brew.nix             # Homebrew
    ...
```

## Host Inheritance

| Host | Imports |
|------|---------|
| semi, dsd | `common/workstation.nix` (shared Juspay config) |
| mach | Individual (personal laptop, media mount) |
| obox | Individual (VPS, hub services) |
| jp-mbp | `darwin/default.nix` (macOS base) |

## Secrets Split

```
secrets/
  office.yaml   → semi, dsd    (office age key)
  server.yaml   → obox, mach   (office age key, shared)
  keys.yaml     → key generation (personal age key)
```

`.sops.yaml` defines creation rules mapping files to age keys.

## Deployment Flow

```
just deploy <host>
  → nh os switch .#<host>
    → nix builds the system closure
    → activates the new generation
    → sops decrypts secrets to /run/secrets/
    → services start with secrets wired
```
