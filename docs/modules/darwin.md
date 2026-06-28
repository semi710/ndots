# Darwin Modules

nix-darwin system modules live in `modules/darwin/`. Each is exposed as `flake.darwinModules.<name>`.

## Available Modules

| Module | Flake output | Description |
|---|---|---|
| [base](#basenix-defaultnix) | `darwinModules.default` | Base macOS: nix settings, settings, brew, stylix, sharedModules |
| [settings](#settings) | `darwinModules.settings` | macOS system defaults, fonts, keyboard, PAM |
| [yabai](#yabai) | `darwinModules.yabai` | Yabai tiling WM + skhd keybindings |
| [brew](#brewnix) | `darwinModules.brew` | Homebrew casks, formulae, mas apps |
| [stylix](#stylixnix) | `darwinModules.stylix` | Stylix theming for Darwin |
| [sharedModules](#sharedmodulesnix) | `darwinModules.sharedModules` | Shared home-manager modules for all users |

## Importing

```nix
{ flake, ... }: {
  imports = [
    flake.darwinModules.default   # base: settings + brew + stylix + sharedModules
    flake.darwinModules.yabai     # window manager
  ];
}
```

---

## base.nix - `default.nix`

The base Darwin module. Wires together all the pieces:

```nix
imports = [
  flake.flakeModules.nix        # nix settings (latest nix, gc, registry, caches)
  flake.darwinModules.settings  # macOS system defaults
  flake.darwinModules.brew      # Homebrew
  flake.darwinModules.stylix    # theming
  flake.darwinModules.sharedModules  # shared home-manager modules
];
home-manager.backupFileExtension = "backup";
```

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.darwinModules.default ];
}
```

---

## settings

Auto-imported directory (`modules/darwin/settings/`). Import via `darwinModules.settings`.

### system.nix

macOS system defaults via `system.defaults`:

| Category | Settings |
|---|---|
| **Fonts** | nerd-fonts.jetbrains-mono, monaspace |
| **Shell** | zsh enabled |
| **PAM** | sudo_local: Touch ID auth + reattach |
| **Keyboard** | KeyMapping enabled, caps lock → escape |
| **Trackpad** | Clicking enabled |
| **Finder** | Show extensions, no desktop icons, path bar, quit menu |
| **Dock** | Autohide (0.1 delay), static-only, no recents, magnification, scroll-to-open |
| **NSGlobalDomain** | Dark mode, fast key repeat, 24h time, metric units, no press-and-hold, window drag gesture |
| **Control Center** | Bluetooth/Display/Sound/Battery/Focus/AirDrop hidden |
| **Spaces** | spans-displays = false (for AeroSpace) |
| **Screenshots** | Thumbnail shown, target = clipboard |

!!! note "Spaces spans-displays"
    `spaces.spans-displays = false` is set for AeroSpace compatibility. For yabai, this should be `true`.

### builder.nix

nix-darwin Linux builder (for cross-compiling to Linux from macOS). **Disabled by default** (`enable = false`).

When enabled, provides a VM with:
- x86_64-linux + aarch64-linux systems
- Docker, 6 cores, 16GB RAM, 1TB disk
- Passwordless sudo, binfmt emulation

```nix
nix.linux-builder = {
  enable = true;
  systems = [ "x86_64-linux" "aarch64-linux" ];
};
```

!!! tip "jp-mbp uses remote builders instead"
    jp-mbp delegates builds to semi/dsd over SSH (configured in its `default.nix`), not the local linux-builder.

---

## yabai

Auto-imported directory (`modules/darwin/yabai/`). Import via `darwinModules.yabai`.

### default.nix

[Yabai](https://github.com/koekeishiya/yabai) tiling window manager. `enableScriptingAddition = true` unlocks focus/stacking control beyond macOS defaults (requires partial SIP disable - the trade-off for Linux-WM-level window management on macOS).

- `enableScriptingAddition = true` (requires partial SIP disable)
- BSP layout, focus follows mouse (autofocus), mouse follows focus
- Window opacity, 10px gaps, float shadow
- Signals: reload SA on dock restart, opacity transitions on Mission Control
- Unmanaged apps: System Settings, Calculator, Karabiner, Finder, etc.
- Comms apps → comms space (Slack, Discord, Telegram, Signal)
- Spaces labeled 1-9 + comms

### skhd.nix

[skhd](https://github.com/koekeishiya/skhd) keybindings (using `skhd-zig`, a Zig port).

**Mod:** `cmd + alt + ctrl` (Hyper key)

- Special mode (`0x29` / backtick): resize, rotate, balance, split, warp cursor - with Hammerspoon visual indicator
- App toggles: return → kitty, b → Zen, s → Slack
- hjkl focus/move (via utils helpers), n/p workspace cycle
- space → monitor cycle, shift+space → move to monitor
- 1-9 workspace focus, shift+1-9 move to workspace
- m → toggle bsp/stack layout, shift+m → native fullscreen
- shift+f → float toggle (8:8 grid), o → focus recent, c → comms space

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.darwinModules.yabai ];
}
```

---

## brew.nix

Homebrew management via nix-darwin.

**Taps:**

- `xykong/tap`, `thusvill/livewallpaper` (both `trusted = true`)

**Casks (GUI apps):**

betterdisplay, blip, cleanupbuddy, element, homerow, hiddenbar, hyperkey, pronotes, finetune, imageoptim, shottr, keycastr, localsend, flux-markdown, livewallpaper, fliqlo, maccy, numi, protonvpn, steam, utm, whatsapp, whisky, windows-app, zulip

**Brews (CLI):**

None currently (tart moved to nix home packages - see [home/packages.nix](home.md#packagesnix)).

**Mas (App Store):**

handmirror, gifski, gladys, tailscale, amphetamine

**Settings:**

- `onActivation`: upgrade + autoUpdate + cleanup "zap" + force-cleanup
- `global.brewfile = true`, `greedyCasks = true`

!!! note "Karabiner not in brew"
    Karabiner-Elements is intentionally not in the cask list (it's managed separately - see [home/darwin/karabiner.nix](home.md#karabinernix)).

---

## stylix.nix

Wires the Stylix darwin module + the shared home stylix config:

```nix
imports = [
  flake.inputs.stylix.darwinModules.stylix
  (flake + /modules/home/stylix/config.nix)
];
```

The theme (kanagawa-dragon, Monaspace fonts) is shared with NixOS via `modules/home/stylix/config.nix`.

---

## sharedModules.nix

Home-manager modules shared across all Darwin users:

```nix
home-manager.sharedModules = [
  flake.homeModules.default    # base home (shell, editor, ssh, fonts)
  flake.homeModules.packages   # GUI packages, nixcord
  flake.homeModules.terminal   # kitty
  flake.homeModules.mpv        # media player
  flake.homeModules.zathura    # PDF viewer
  flake.homeModules.browser    # Zen browser
];
```

This gives every Darwin user the full desktop app set without per-user repetition.
