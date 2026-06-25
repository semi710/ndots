# jp-mbp — MacBook Pro M4

| | |
|---|---|
| **Platform** | nix-darwin aarch64 |
| **CPU** | Apple M4 |
| **User** | nikhil.singh |

## Window Management

- **Yabai** — tiling window manager (with skhd keybindings)
- **Aerospace** — alternative tiling WM (with custom bindings)
- **Janky Borders** — window focus borders

## Input

- **Karabiner-Elements** — keyboard remapping
- **Hammerspoon** — automation and scripting

## Packages

Managed via Homebrew (Nix Casks):

```nix
# modules/darwin/brew.nix
homebrew.casks = [ ... ];
homebrew.brews = [ ... ];
```

## Theming

- **Stylix** — consistent theming across CLI tools
- CLI-only theme (no desktop wallpaper management on macOS)

## Files

- `hosts/darwin/jp-mbp/default.nix` — main config
- `modules/darwin/` — Darwin system modules
- `modules/home/darwin/` — Darwin home-manager modules
