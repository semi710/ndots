# Custom Packages

Custom packages live in `packages/` and are auto-discovered by nix-wire, exposed as `self.packages.${system}.<name>`. They're also re-exposed into `pkgs` via the overlay in `overlays/packages.nix`.

## Available Packages

| Package | Platforms | Description |
|---|---|---|
| [copy](#copy) | unix | OSC52 clipboard utility (works over SSH + tmux) |
| [aria2tui](#aria2tui) | unix | TUI frontend for aria2c |
| [sklauncher](#sklauncher) | linux + darwin | Minecraft launcher (SKLauncher) |
| [stremio-enhanced](#stremio-enhanced) | darwin (aarch64) | Stremio with premium addons |
| [airsync](#airsync) | darwin | Android-to-Mac file transfer |
| [hammerspoon](#hammerspoon) | darwin | macOS automation (Hammerspoon app) |
| [skhd-zig](#skhd-zig) | darwin | Zig port of skhd hotkey daemon |
| [road-rage](#road-rage) | all | Punky display font (used in hyprlock) |

## Using Packages

```bash
# Run directly from the flake
nix run github:semi710/ndots#copy -- "hello"

# Or in your own flake
{
  inputs.ndots.url = "github:semi710/ndots";
  outputs = { self, nixpkgs, ndots, ... }: {
    # Via overlay (recommended - gives pkgs.copy etc.)
    nixpkgs.overlays = [ ndots.overlays.default ];

    # Or directly
    environment.systemPackages = [
      ndots.packages.x86_64-linux.copy
    ];
  };
}
```

---

## copy

`packages/copy.nix`

A minimal shell script that copies stdin to the system clipboard via [OSC52](https://en.wikipedia.org/wiki/ANSI_escape_code#OSC_52) escape sequences. Works over SSH and inside tmux.

**How it works:**

1. Reads text from stdin
2. Base64-encodes it
3. If inside tmux: wraps in the `tmux;` passthrough sequence
4. Otherwise: sends the raw OSC52 sequence
5. The terminal emulator writes to the local clipboard (not the remote machine's)

```bash
echo "hello" | copy       # copies "hello"
printf '%s' "$BUFFER" | copy  # from zsh
```

!!! tip "Why this exists"
    Standard clipboard tools (`xclip`, `pbcopy`) don't work over SSH. OSC52 is a terminal protocol that tells the *local* terminal to copy to the *local* clipboard, even when you're on a remote machine. This is used throughout the shell config (zsh visual yank, tmux fzf-url, lazygit).

---

## aria2tui

`packages/aria2tui.nix`

A Python TUI frontend for the [aria2c](https://aria2.github.io/) download manager. Built from [grimandgreedy/aria2tui](https://github.com/grimandgreedy/aria2tui).

- Includes a vendored `listpick` dependency
- Bundles the default config to `$out/share/aria2tui/`

```bash
nix run github:semi710/ndots#aria2tui
```

---

## sklauncher

`packages/sklauncher.nix`

[SKLauncher](https://skmedix.pl/) - a Minecraft launcher. Builds for both Linux and Darwin with platform-specific packaging.

**Linux:**

- Wrapped with `steam-run` (for the Minecraft runtime)
- Desktop entry + icon installed
- JDK 21 bundled

**Darwin:**

- `.app` bundle with Info.plist
- Icon converted PNG → ICNS via ImageMagick
- JDK 21 launcher script

```bash
nix run github:semi710/ndots#sklauncher
```

!!! warning "Unfree license"
    SKLauncher is unfree. The package sets `meta.license = lib.licenses.unfree`.

---

## stremio-enhanced

`packages/stremio-enhanced.nix`

[Stremio Enhanced](https://github.com/REVENGE977/stremio-enhanced) - Stremio with premium addons. macOS arm64 only (fetches a pre-built `.zip`).

```bash
nix run github:semi710/ndots#stremio-enhanced
# Installs to $out/Applications/
```

---

## airsync

`packages/airsync.nix`

[AirSync](https://github.com/sameerasw/airsync-mac) - Android-to-Mac file transfer (KDE Connect alternative). macOS only, fetches a `.dmg`.

```bash
nix run github:semi710/ndots#airsync
# Installs to $out/Applications/
```

---

## hammerspoon

`packages/hammerspoon.nix`

[Hammerspoon](https://www.hammerspoon.org/) - macOS desktop automation with Lua. Fetches the official release zip.

This packages just the `.app` bundle. The actual `init.lua` config is in [modules/home/darwin/hammerspoon.nix](../modules/home.md#hammerspoonnix).

```bash
nix run github:semi710/ndots#hammerspoon
```

---

## skhd-zig

`packages/skhd-zig.nix`

A [Zig port of skhd](https://github.com/jackielii/skhd.zig) (simple hotkey daemon for macOS). Fully `.skhdrc` compatible. Fetches pre-built binaries.

Used by the [yabai module](../modules/darwin.md#yabai) instead of upstream skhd.

```bash
nix run github:semi710/ndots#skhd-zig
```

---

## road-rage

`packages/road-rage/default.nix`

The [Road Rage](https://www.dafont.com/road-rage.font) punky display font. Installs the `.ttf` to `$out/share/fonts/`.

Used by the [hyprlock](../modules/home.md#hyprlocknix) screen lock for the large clock display.

```nix
{ pkgs, ... }: {
  home.packages = [ pkgs.road-rage ];
  # Font is available system-wide via fontconfig
}
```
