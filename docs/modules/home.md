# Home Modules

Home-manager modules live in `modules/home/`. Each is exposed as `flake.homeModules.<name>`.

## Available Modules

| Module | Flake output | Description |
|---|---|---|
| [base](#basenix-defaultnix) | `homeModules.default` | Base home: shell, editor, ssh, fonts, nix-index |
| [shell](#shell) | `homeModules.shell` | zsh, tmux, fzf, starship, git, bat, btop, direnv, eza, zoxide, jq, sesh, aliases, android |
| [editor](#editor) | `homeModules.editor` | Helix, nvix (Neovim) |
| [ai](#ai) | `homeModules.ai` | s-ai agents (opencode, omp, pi) + juspay provider |
| [browser](#browser) | `homeModules.browser` | Zen browser (base, extensions, keymaps, search) |
| [terminal](#terminal) | `homeModules.terminal` | kitty terminal |
| [hyprland](#hyprland) | `homeModules.hyprland` | Hyprland home config, rofi, hypridle, hyprlock, keymaps |
| [darwin](#darwin) | `homeModules.darwin` | aerospace, karabiner, hammerspoon, jankyborders |
| [stylix](#stylix) | `homeModules.stylix` | Stylix theming (config + cli-only mode) |
| [packages](#packagesnix) | `homeModules.packages` | GUI packages + nixcord (not meant for external use) |
| [syncthing](#syncthingnix) | `homeModules.syncthing` | Cross-device file sync |
| [sops](#sopsnix) | `homeModules.sops` | Home-level sops secrets |
| [ssh](#sshnix) | `homeModules.ssh` | SSH client config + agent |
| [naste](#nastenix) | `homeModules.naste` | naste CLI client (endpoint pre-configured) |
| [mpv](#mpvnix) | `homeModules.mpv` | Media player with modernx OSC |
| [zathura](#zathuranix) | `homeModules.zathura` | PDF/document viewer |
| [aria2](#aria2nix) | `homeModules.aria2` | aria2 download manager |
| [nix-index](#nix-indexnix) | `homeModules.nix-index` | `,` command (run unknown binaries) |
| [nix-conf-fix](#nix-conf-fixnix) | `homeModules.nix-conf-fix` | Fix attic's bare `substituters` in user nix.conf |
| [home-only](#home-onlynix) | `homeModules.home-only` | For standalone home-manager (adds flakeModules.nix) |

## Importing

```nix
{ flake, ... }: {
  imports = [
    flake.homeModules.default    # shell, editor, ssh, fonts
    flake.homeModules.ai         # AI tooling
    flake.homeModules.stylix     # theming
  ];
}
```

!!! note "In NixOS/Darwin hosts"
    When used inside a NixOS or Darwin host, home modules are added via `home-manager.sharedModules`. The NixOS `default.nix` and Darwin `sharedModules.nix` wire this automatically.

## Design Philosophy

A few deliberate choices repeat across these modules. They explain the per-module details below:

- **vi-mode / hjkl everywhere** - zsh, tmux, kitty, hyprland, mpv, zathura, rofi, aerospace, and skhd share the same motion keys. One muscle memory set works across shell, terminal, window manager, and media apps.
- **`jk` escape** - the same escape chord in zsh, opencode, and Hammerspoon's system-wide vim mode. Leaving insert mode is identical everywhere.
- **OSC52 clipboard** - visual yank reaches the local clipboard over SSH and inside tmux, with no xclip forwarding or extra config.
- **Shared stylix theme** - kanagawa-dragon colors and Monaspace fonts flow from NixOS to Darwin to home-manager, so every app reads the same theme - no per-app configuration.
- **nix-wire auto-import** - drop a `.nix` into a module directory and it's wired automatically. That's why `shell/`, `editor/`, `ai/`, etc. are directories with a `default.nix` that imports its siblings - no import list to maintain.

---

## base.nix - `default.nix`

The base home setup every user gets - the foundation all other home modules layer on. Platform-agnostic on purpose: one module works on NixOS, Darwin, and standalone home-manager, so there's no per-OS fork of the common user environment.

**What it does:**

- Sets `home.stateVersion = "26.05"`
- Enables fontconfig
- Imports: `shell`, `editor`, `ssh`, `nix-index`, `aria2`, `nix-conf-fix`
- Installs fonts: noto (sans, emoji, CJK), carlito, ipafont, kochi-substitute, source-code-pro, dejavu, nerd-fonts (jetbrains-mono, fira-code, droid-sans-mono)

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.default ];
}
```

---

## shell

Auto-imported directory (`modules/home/shell/`). Import via `homeModules.shell`.

### default.nix

The shell bundle - everything that makes the terminal usable. Adding `foo.nix` here wires it automatically (no import list to touch); `nix-your-shell` so `nix-shell -p` works inside zsh.

- Imports all shell sub-modules via `nix-wire.lib.autoImport`
- Enables `nix-your-shell`
- Installs: `devenv`, `nixpkgs-track`, `nixpkgs-manual`, `nixpkgs-review`, `nh`, `duf`

### zsh.nix

Zsh as the primary shell, configured so editor muscle memory carries over and the clipboard works remotely. vi-mode + `jk` escape match the editor/tmux chords; OSC52 so visual yank reaches the local clipboard over SSH and tmux; fzf-tab so completion is fuzzy instead of prefix-only.

- `zsh-vi-mode` plugin (escape with `jk`)
- `zsh-fzf-tab` plugin (`Alt+j`/`Alt+k` complete)
- Autosuggestions + syntax highlighting
- OSC52 copy integration (visual yank → clipboard, works over SSH/tmux)
- Re-adopts the forwarded agent socket from tmux's environment when the current one is dead, so git push keeps working in old panes after disconnect/reconnect
- `runbg` function (resume a Ctrl+Z'd job in background)
- Sources `~/.temp.zsh` if it exists

### tmux.nix

Tmux as the session/pane layer, kept consistent with the shell and editor. Vi mode for hjkl navigation; `Ctrl+a` prefix (easier to reach than the default `Ctrl+b`); OSC52 copy so yanks work over SSH without xclip forwarding; minimal status line so panes get the screen space.

- `baseIndex = 1`, `keyMode = "vi"`, `shortcut = "a"` (prefix is `Ctrl+a`)
- Plugins: `minimal-tmux-status`, `better-mouse-mode`, `fzf-tmux-url` (`u`), `vim-tmux-navigator`
- OSC52 copy via the `copy` tool in fzf-url
- `ta <session>` command (attach/create session)
- `Ctrl+e` edits pane output in `$EDITOR`
- Extended keys forced (`extended-keys always`, CSI-u format) so modified keys survive the SSH+tmux hop: Shift+Enter reaches TUI apps as `\x1b[13;2u` (newline) instead of collapsing to `\r` (submit). Apps that never request extended keys still get CSI-u for keys without a legacy sequence; Enter and Ctrl+J keep their standard bytes. In opencode: Shift+Enter and Ctrl+J insert a newline, Enter submits.
- Splits: `|` horizontal, `-` vertical, `v`/`s` (open in cwd)
- `alt+h`/`alt+l` translate to Left/Right at the tmux root table, so omp selectors and opencode dialogs accept them as tab switches; copy-mode-vi keeps native motion

### fzf.nix

Fzf as the universal fuzzy picker, wired into shell, tmux, and git. `fd` replaces `find` (faster, respects gitignore by default); ripgrep powers preview content search.

- Default options: 60% height, reverse layout, highlight line, custom colors
- `fd` as the file finder (hidden, follow symlinks)
- `fzf-preview` for previews
- `nix-search-tv` package (fuzzy nixpkgs search)
- `Ctrl+R` history, `Ctrl+Space` accept autosuggestion (wired in zsh init; requires reassigning macOS input source shortcut away from Ctrl+Space + reboot)
- `fzfp` alias for fzf with preview

### starship.nix

Custom starship prompt that surfaces git state and dev-shell context at a glance. Two-line so the verbose git info (branch, last commit, status counts) sits on its own line and never eats into the command line.

- Shows: directory icon, file count, folder count, disk usage
- Git: branch, host icon (github/gitlab/etc), last commit message, status with counts
- Two-line prompt (git info on second line)
- Vim mode character (`vimcmd_symbol`)
- Nix shell state indicator (impure/pure/unknown)

### git.nix

Git with the surrounding tooling (`gh`, `lazygit`) and defaults that keep history clean and resolvable. `pull.rebase` for linear history; `diff3` conflict style so the original context is visible during merges; `rerere` so repeated conflicts auto-resolve.

- `pull.rebase = true`, `merge.conflictStyle = "diff3"`, `rerere.enabled`
- `init.defaultBranch = "master"`, `core.editor = "nvim"`
- `gh` with `gh-notify` extension
- `lazygit` with nvim-remote edit preset, OSC52 clipboard
- `gfm <branch> [remote]` helper (fetch + merge)
- `git-addnospace` alias (stage ignoring whitespace)
- Git maintenance enabled for `~/work/nixpkgs`

### bat.nix

`cat` replacement that adds syntax highlighting and line numbers for free. Aliased so `cat` muscle memory carries over - pipe to it or read a file, same invocation.

- `bat` enabled
- `cat` aliased to `bat --paging=never --style=plain`

### btop.nix

`top`/`htop` replacement, configured with vim keys so you navigate processes with hjkl - same motions as the shell and editor.

- `btop` with `vim_keys = true`, transparent background

### direnv.nix

Auto-loads the nix dev shell when you `cd` into a project, so there's no manual `nix-shell`/`nix develop` per visit. `nix-direnv` keeps the shell cached (fast reloads).

- `direnv` + `nix-direnv`, silent, zsh integration

### eza.nix

`ls` replacement that adds git status per file, icons, and colors. Aliased onto `ls`/`lt` so the same muscle memory gives a richer view with zero retraining.

- `eza` with colors, git, icons, group/header/smart-group
- Aliases: `ls` → `eza -s modified --reverse`, `lt`/`tree` → tree view

### zoxide.nix

`cd` replacement that learns your frequent directories - `cd proj` jumps to the right one instead of typing the full path. Bound as `cd` directly; `/nix` excluded because store paths aren't useful jump targets.

- `zoxide` with `--cmd cd` (replaces `cd` with zoxide)
- Excludes `/nix`

### jq.nix

JSON CLI. Enabled so it's on PATH and available to the fzf/nsearch tooling above for ad-hoc JSON inspection.

- `jq` enabled

### sesh.nix

[sesh](https://github.com/joshmedeski/sesh) tmux session manager - so you don't recreate the same sessions every time you switch projects. Predefined sessions (`todo`, `notes`, `LeetCode`, `main`) mean one keystroke opens the full workflow.

- Pinned to v2.25.0 (overridden hash)
- `tmuxKey = "c-o"` (open sesh from tmux)
- Predefined sessions: `todo` (opens todo.md in nvim), `notes` (ObsidianQuickSwitch), `LeetCode` (Leet command), `main`
- Blacklist: scratch, Library, Applications, Pictures
- `Ctrl+p` in tmux → `sesh last`

### aliases.nix

Shell aliases + the `nxbuild` helper. `nxbuild` exists to offload nix builds to remote machines (semi/dsd) so the local machine doesn't melt - the rest are shortening aliases (`c`, `d`, colored `cp`/`rm`) and a `help` that pipes through bat.

- Aliases: `c` (clear), `d` (background), `cp`/`rm`/`rcp` (colored/verbose), `mkdir -pv`, `isodate`, `matrix`, `fetch` (fastfetch), `font-family`
- `help` command (pipes `--help` through bat)
- **`nxbuild`** - build nix packages on remote builders. Usage:
  ```bash
  nxbuild semi .#iso          # ad-hoc builder
  nxbuild .#iso               # configured builders
  nxbuild dsd -j 4 nixpkgs#hello
  ```

### android.nix

Android device tooling: `android-tools` for `adb`/`fastboot`, `scrcpy` for low-latency screen mirroring and control over USB.

- Installs `android-tools` + `scrcpy`

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.shell ];
  # All shell tools above
}
```

---

## editor

Auto-imported directory (`modules/home/editor/`). Import via `homeModules.editor`.

### helix.nix

A second editor alongside nvix. Relative line numbers so `5j`/`3k` motions stay accurate; LSP messages surfaced inline.

- `helix` with relative line numbers, LSP display messages

### nvix/default.nix

[Neovim via the nvix flake](https://github.com/semi710/nvix). Exposes an option:

| Option | Type | Default | Description |
|---|---|---|---|
| `nvix.variant` | enum `["bare" "core" "full"]` | `"core"` | Which nvix variant to install |

- Sets `EDITOR = "nvim"`, `vimAlias = true`
- Codesnap watermark font set to CaskaydiaCove
- Colorscheme: catppuccin disabled (kanagawa-dragon used via stylix instead)

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.editor ];
  nvix.variant = "full";  # or "bare" for minimal
}
```

!!! tip "ISO uses bare"
    The installer ISO forces `nvix.variant = "bare"` to keep the image small.

---

## ai

One file (`modules/home/ai/default.nix`): consumes the [s-ai](https://github.com/semi710/s-ai) flake module (local `~/work/s-ai` checkout while iterating, flip to the GitHub URL once pushed), which owns the agents - opencode, oh-my-pi (omp), pi - and the shared canonical layer: skills, prompts, MCP servers, provider renders, themes. Import via `homeModules.ai`.

ndots supplies only what is host-specific:

- Provider: the juspay grid - baseUrl plus an env-var name; the key itself comes from sops-managed env, never the store
- Theme: `s-ai.theme.palette` filtered from `config.lib.stylix.colors`, so the omp theme follows kanagawa-dragon
- Skills: `s-ai.plugins.workmux.enable = true` (worktree/tmux workflow skills)
- pi: `agents.pi.clipboardCommand` - OSC 52 yank via our `copy` tool
- opencode-only providers: anthropic (the named models), Zen gateway (`OPENCODE_API_KEY`), OpenRouter (`OPENROUTER_API_KEY`)
- Packages: `openspec`, `nil` (nix LSP; omp auto-detects it from flake.nix root markers and wires diagnostics/imports into edits)

Everything else is s-ai defaults: all three agents enabled, core/ponytail/claude-code plugins on, omp memory/advisor/prewalk on, the universal MCP set, vim-mode TUIs, keybindings, themes derived from the palette. Toggle per host with the `s-ai.*` options; anything not exposed as an option is overridable through the per-agent `extraSettings` escape hatch (deep-merged last). See the s-ai README for the full option reference.

### MCP servers

Rendered from s-ai's canonical set: git, fetch, sequential-thinking, everything (filesystem), playwright, deepwiki (remote), nixos, context7 (remote), grep_app (remote), codegraph. Work hosts set `s-ai.mcp.workServers = true`, which adds github and newton-hs-prod; the workstation module adds `bitbucket` at the `programs.mcp.servers` level. Every agent render (opencode MCP integration, pi's `mcp.json`, omp's `mcp.json`) reads the merged set, so host-level additions land in every agent.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.ai ];
  # all three agents + juspay provider + stylix theme
}
```


---

## browser

Auto-imported directory. Import via `homeModules.browser`. Web browser config - Zen (Firefox-based); containers keep Personal and Work logins from bleeding into each other.

### zen/

Zen Browser (Firefox-based) via the `zen-browser` flake.

#### base.nix

- Containers: Personal (purple), Work (blue)
- 9 Zen mods (Quietify, PiP tweaks, Transparent Zen, Better CtrlTab, etc.)
- Session restore on startup, workspaces enabled, window sync
- Transparency enabled (for Transparent Zen mod)
- Policies: disable telemetry, studies, pocket, app update; tracking protection locked
- MIME associations: Zen as default for http/https/html/mailto/etc.

#### extensions.nix

Extensions via `rycee/firefox-addons` + AMO policies:

- rycee: ublock-origin, darkreader, simple-translate, firenvim, auto-tab-discard, duckduckgo, vimium, refined-github
- AMO: iCloud Passwords, Material Icons for GitHub, GitOwl, Nixpkgs PR Tracker, LanguageTool, Wide GitHub

#### keymaps.nix

Custom Zen keyboard shortcuts (compact mode, sidebar, workspaces, split views, pin, glance, copy URL).

#### search.nix

Custom search engines: DuckDuckGo default, hidden Google/Bing/Amazon/eBay. Added: Nix Packages (`@np`), Nix Options (`@no`), Home Manager (`@hm`), GitHub (`@gh`).

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.browser ];
}
```

---

## terminal

Auto-imported directory. Import via `homeModules.terminal`.

### kitty.nix

Kitty terminal with Monaspace fonts (with ligatures), transparency, cursor trail.

- Background opacity 0.85, blur 32, titlebar-only decorations
- Monaspace Radon Var font with all ligature features (dlig + ss01-ss08)
- Custom `tab_bar.py` (from `misc/`)
- Cursor: beam with trail, blink
- `shift+enter` sends the kitty extended sequence
- macOS: `cmd+opt` as alt, option-as-alt yes
- MIME: vim-style keybindings (h/l seek, j/k cycle sub/audio)
- Stats overlay: JetBrainsMono, vim-style scroll

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.terminal ];
}
```

---

## hyprland

Auto-imported directory (`modules/home/hyprland/`). Import via `homeModules.hyprland`.

### default.nix

- Auto-starts Hyprland via UWSM on TTY login (when no SSH + no tmux)
- Installs `grim`, `slurp`, `wl-clipboard`
- Aliases: `copy` → `wl-copy`, `paste` → `wl-paste`

### config.nix

Main Hyprland settings (Stylix-colored):

- `$mod = SUPER`, dwindle layout, gaps 2/4, border 2
- Input: US layout, follow mouse, touchpad natural scroll, repeat 50/300
- Group tabs with stylix colors, no gradients, 5px height
- Decoration: rounding 10, blur (size 6, passes 3, popups), no shadow
- Animations: custom bezier curves for windows/fade/workspaces
- Misc: swallow enabled, DPMS on mouse/key, session lock restore

### keymaps.nix

Full keybind set (SUPER mod). Includes workspace navigation, window movement, focus (hjkl), resize, screenshots (grimblast), volume/brightness (utils), special workspaces (comms, quick), group submap, pass-through submap, rofi launcher.

Also sets up XDG user dirs (Screenshots) and installs `grimblast`, `scratchpad`, `volume`, `brightness` from hyprland-contrib + utils.

### monitor.nix

Options for monitor setup:

| Option | Type | Default | Description |
|---|---|---|---|
| `ndots.hyprland.monitor.primary` | str | `"DP-3"` | Primary monitor |
| `ndots.hyprland.monitor.secondary` | str | `"DP-4"` | Secondary monitor |

Disables eDP-1, 10-bit color, secondary rotated (transform 3). Workspaces 1-9 on primary, 10 on secondary. IPC listener auto-runs monitor reconfigure on hotplug.

### hypridle.nix

Idle daemon: lock at 290s, DPMS off at 300s, suspend at 360s.

### hyprlock.nix

Screen lock with screenshot background (blurred), Road Rage font clock, stylix-colored input field.

### rules.nix

Window/layer rules: float dialogs, comms apps to special workspace, blur on browsers/discord, idle inhibit for fullscreen video, quick-term dropdown styling.

### rofi/

Rofi launcher (Wayland) with stylix-disabled theme, vim keys (Ctrl+hjkl). Keymaps bind `Alt+Space` leader for network/bluetooth/audio/emoji/power menus.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.hyprland ];
  ndots.hyprland.monitor.primary = "DP-1";
}
```

---

## darwin

Auto-imported directory (`modules/home/darwin/`). Import via `homeModules.darwin`.

### aerospace/

[AeroSpace](https://nikitabobko.github.io/AeroSpace/) tiling WM for macOS.

#### settings.nix

- Start at login, gaps 8, accordion padding 120
- Workspace-to-monitor assignments (1-5 primary, 6-9 secondary, 10 secondary)
- Floating apps: System Settings, Calculator, Finder, mpv, etc.
- Comms apps → Comms workspace (telegram, slack, discord, signal, etc.)
- After startup: borders + kitty dmenu panel

#### bindings.nix

Full keybinds with `cmd-alt` mod (capslock mapped to cmd-alt via Karabiner):

- hjkl focus (with mouse follow + wrap-around all monitors)
- shift+hjkl move, shift+space monitor swap, space monitor focus
- 1-0 workspaces, n/p next/prev, shift+1-0 move to workspace
- slash → fzf focus picker (via kitty panel)
- enter → kitty, m → fullscreen, f → float/tiling toggle
- Resize mode (hjkl), service mode (reload, flatten, enable toggle)

#### binding-script.nix

Floating window management via AppleScript:

- `movefloating` - move floating window by offset (shift+arrows)
- `resizefloating` - resize floating window (ctrl+hjkl)
- `centerfloating` - center + 3/5 size floating window (ctrl+shift+c)

### karabiner.nix

Installs the `quick_hyper.karabiner.json` complex modification (from `misc/`). Must be imported manually in Karabiner-Elements.

### hammerspoon.nix

[Hammerspoon](https://www.hammerspoon.org/) automation. Installs the Hammerspoon app + a large `init.lua`:

- **Hammerspoon Mode** (`Ctrl+Opt+Shift+H`): keyboard brightness control, reload, with visual indicator
- **SKHD Special Mode indicator**: shows "SPECIAL" overlay when skhd special mode is active
- **VimMode spoon**: system-wide vim mode (enter with `jk`), with extensive guards:
  - Disables in Code, MacVim, zoom, kitty, Maccy, Homerow, Minecraft
  - Password field guard (disables in secure text fields)
  - Firenvim guard (disables in browser-embedded Neovim)
  - Hyper key guard (temporarily disables sequence during Hyper modifier)
  - Spotlight + Emoji picker support
  - Custom glass-style N/V mode indicator

### jankyborders.nix

Focus borders for macOS.

- Style: round, width 1.0, HiDPI on
- Blacklist: ~25 system/utility apps (Finder, Messages, Calculator, etc.)

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.darwin ];
  # aerospace + karabiner + hammerspoon + jankyborders
}
```

---

## stylix

Import via `homeModules.stylix`.

### default.nix

Wires the stylix home-manager module + config + cli-only mode.

### config.nix

The shared theme config (used by NixOS, Darwin, and home-manager):

| Setting | Value |
|---|---|
| `base16Scheme` | `kanagawa-dragon` |
| `image` | gruvbox pixelart wallpaper |
| `opacity.terminal` | `0.4` |
| `polarity` | `dark` |
| `fonts.monospace` | Monaspace Radon Var |

### cli-only.nix

Adds a `stylix.cliOnly` option. When enabled, disables GUI targets that require dconf/GTK (for headless/CLI-only setups):

```nix
stylix.cliOnly = true;  # disables gtk, gtksourceview, gnome, gnome-text-editor, eog targets
```

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.stylix ];
  stylix.cliOnly = true;  # for servers / CLI-only users
}
```

---

## packages.nix

GUI packages + nixcord. **Not meant for external use** - contains personal app preferences.

- Both platforms: google-chrome, telegram-desktop, tart, softnet
- Darwin: mas, bruno, ytmdesktop
- nixcord: Discord client with messageLogger, showMeYourName, fakeNitro plugins, vencord enabled

---

## syncthing.nix

Peer-to-peer file sync. Devices: mach, dsd, semi, jp-mbp. Folders: `~/.notes`, `~/.dump`.

!!! warning "Use absolute paths"
    Syncthing doesn't expand `~`. Paths use `config.home.homeDirectory`.

```nix
folders."${config.home.homeDirectory}/.notes" = {
  id = "notes";
  devices = [ "mach" "dsd" "semi" "jp-mbp" ];
};
```

---

## sops.nix

Home-level sops. Age key at `~/.config/sops/age/keys.txt`, default file `secrets/keys.yaml`. Sets `SOPS_AGE_KEY_FILE` env var.

---

## ssh.nix

SSH client config.

- `forwardAgent = true`, `addKeysToAgent = "yes"`
- `sendEnv`: `JUSPAY_*`, `GITHUB_*`, `ANTHROPIC_*`, `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`
- Darwin: `useKeychain = true`
- Forces `.ssh/config` (avoids home-manager collision)
- Linux: `ssh-agent` service enabled

---

## mpv.nix

Media player with modernx-zydezu OSC.

- Fonts symlinked for macOS (modernx icons)
- Vim keybindings: h/l seek, j/k cycle subs/audio
- Stats overlay: JetBrainsMono, vim-style
- MIME: default for all video types
- `save-position-on-quit`, `ytdl-format = bestvideo+bestaudio`

---

## zathura.nix

PDF/document viewer (mupdf + djvu + ps backends).

- Vim keybindings (u/d scroll, J/K zoom, R reload, r rotate, i recolor)
- `selection-clipboard clipboard`, sqlite database, minimal UI
- MIME: default for PDF and PowerPoint

---

## aria2.nix

aria2 download manager with optimized settings:

```nix
file-allocation = "falloc";
max-concurrent-downloads = 20;
max-connection-per-server = 10;
split = 4;
min-split-size = "10M";
```

---

## nix-index.nix

[nix-index](https://github.com/nix-community/nix-index) + [nix-index-database](https://github.com/nix-community/nix-index-database).

- `,` (comma) command to run programs not in PATH
- `COMMA_PICKER = fzf` (fzf picker for ambiguous commands)
- Zsh integration enabled

---

## nix-conf-fix.nix

Activation hook that fixes `attic-client`'s bare `substituters`/`trusted-public-keys` in `~/.config/nix/nix.conf` by converting them to `extra-` prefixed equivalents (needed for multi-user Nix where user-level bare settings are ignored).

---

## home-only.nix

For standalone home-manager (not NixOS/Darwin). Adds `homeModules.default` + `flakeModules.nix` (nix settings).

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.home-only ];
}
```

---

## naste.nix

naste CLI client with endpoint pre-configured. Imported by `homeModules.default` (all users). Hosts with sops add `private.userFile`/`passFile` in their user config.

```nix
{ flake, ... }: {
  imports = [ flake.inputs.naste.homeModules.default ];
  programs.naste-client = {
    enable = true;
    endpoint = "https://paste.semi.sh";
  };
}
```

See [naste service docs](../services/naste.md) for private credential setup per host.
