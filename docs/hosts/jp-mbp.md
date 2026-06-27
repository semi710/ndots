# jp-mbp - MacBook Pro M4

| | |
|---|---|
| **Platform** | nix-darwin aarch64 |
| **CPU** | Apple M4 |
| **User** | nikhil.singh |
| **State version** | 6 |

## Modules Imported

```nix
imports = [
  flake.darwinModules.default    # base: settings, brew, stylix, sharedModules
  flake.darwinModules.yabai      # window manager + skhd
  flake.inputs.sops-nix.darwinModules.sops
];
```

The [darwin default](../modules/darwin.md#basenix-defaultnix) module wires: [nix settings](../modules/flake.md), [system settings](../modules/darwin.md#settings), [Homebrew](../modules/darwin.md#brewnix), [stylix](../modules/darwin.md#stylixnix), and [shared home-manager modules](../modules/darwin.md#sharedmodulesnix) (default, packages, terminal, mpv, zathura, browser).

## Window Management

Two tiling window managers are available:

- **[Yabai](../modules/darwin.md#yabai)** + skhd-zig (active) - BSP layout, scripting additions, hyper key bindings
- **[AeroSpace](../modules/home.md#darwin)** (home-manager) - alternative tiling WM with cmd-alt bindings (capslock mapped to cmd-alt via Karabiner)
- **[Janky Borders](../modules/home.md#darwin)** - window focus borders

## Input

- **[Karabiner-Elements](../modules/home.md#darwin)** - keyboard remapping (quick_hyper complex modification, capslock → hyper)
- **[Hammerspoon](../modules/home.md#darwin)** - automation: VimMode (system-wide `jk` enter), Hammerspoon Mode, SKHD special mode indicator, password/Firenvim/Homerow guards

## Packages

Managed via [Homebrew](../modules/darwin.md#brewnix) (nix-darwin `homebrew.casks` + `mas`):

betterdisplay, homerow, hiddenbar, hyperkey, shottr, maccy, imageoptim, localsend, steam, utm, whisky, tailscale (mas), amphetamine (mas), and more.

## Theming

- **[Stylix](../modules/darwin.md#stylixnix)** - kanagawa-dragon theme, Monaspace fonts, shared across platforms
- CLI-only theme is **not** used on jp-mbp (it's a desktop machine)

## Remote Builders

jp-mbp delegates nix builds to dsd and semi over SSH:

```nix
nix.distributedBuilds = true;
nix.buildMachines = [
  { inherit (cfg.builders.dsd) hostName system maxJobs speedFactor supportedFeatures sshUser;
    sshKey = config.sops.secrets."private-keys/nix-builder".path; }
  { inherit (cfg.builders.semi) hostName system maxJobs speedFactor supportedFeatures sshUser;
    sshKey = config.sops.secrets."private-keys/nix-builder".path; }
];
```

The builder SSH key comes from sops (`secrets/office.yaml` → `private-keys/nix-builder`).

## macOS Defaults

System settings via [darwin settings module](../modules/darwin.md#settings):

- Dark mode, fast key repeat, caps lock → escape
- Touch ID for sudo (PAM)
- Dock: autohide, static-only, no recents, magnification
- Finder: show extensions, no desktop icons, path bar
- Spaces spans-displays = false (for AeroSpace)

## Secrets

System level uses `secrets/office.yaml` (office age key):

- `private-keys/nix-builder` (SSH key for remote builds)

Home level uses `secrets/keys.yaml` (personal age key):

- `tokens/ai/gemini`, `tokens/ai/openai`, `tokens/ai/openrouter`, `tokens/ai/opencode-zen`
- `tokens/github`, `tokens/cachix`, `tokens/nix-access`
- `ssh/private`, `ssh/office`
- `syncthing/jp-mbp/{password,cert,key}`

Home level also pulls from `secrets/office.yaml`:

- `private-keys/jp-key` (Juspay API key)

And from `secrets/server.yaml`:

- `naste/user`, `naste/pass`

## Files

- `hosts/darwin/jp-mbp/default.nix` - main config
- `modules/darwin/` - Darwin system modules
- `modules/home/darwin/` - Darwin home-manager modules
