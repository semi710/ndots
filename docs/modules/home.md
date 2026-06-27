# Home Modules

Home-manager modules live in `modules/home/`. Each is exposed as `flake.homeModules.<name>`.

## Available Modules

| Module | Flake output | Description |
|---|---|---|
| [base](#basenix-defaultnix) | `homeModules.default` | Base home: shell, editor, ssh, fonts, nix-index |
| [shell](#shell) | `homeModules.shell` | zsh, tmux, fzf, starship, git, bat, btop, direnv, eza, zoxide, jq, sesh, aliases, android |
| [editor](#editor) | `homeModules.editor` | Helix, nvix (Neovim) |
| [ai](#ai) | `homeModules.ai` | opencode, claude, mcp, pi, providers (anthropic, office, zen, openrouter) |
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

---

## base.nix - `default.nix`

The base home setup every user gets. Platform-agnostic (works on NixOS, Darwin, standalone).

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

- Imports all shell sub-modules via `nix-wire.lib.autoImport`
- Enables `nix-your-shell`
- Installs: `devenv`, `nixpkgs-track`, `nixpkgs-manual`, `nixpkgs-review`, `nh`, `duf`

### zsh.nix

Zsh with vi-mode, OSC52 clipboard, fzf-tab.

- `zsh-vi-mode` plugin (escape with `jk`)
- `zsh-fzf-tab` plugin (`Alt+j`/`Alt+k` complete)
- Autosuggestions + syntax highlighting
- OSC52 copy integration (visual yank → clipboard, works over SSH/tmux)
- `runbg` function (resume a Ctrl+Z'd job in background)
- Sources `~/.temp.zsh` if it exists

### tmux.nix

Tmux with vi mode, custom status, plugins.

- `baseIndex = 1`, `keyMode = "vi"`, `shortcut = "a"` (prefix is `Ctrl+a`)
- Plugins: `minimal-tmux-status`, `better-mouse-mode`, `fzf-tmux-url` (`u`), `vim-tmux-navigator`
- OSC52 copy via the `copy` tool in fzf-url
- `ta <session>` command (attach/create session)
- `Ctrl+e` edits pane output in `$EDITOR`
- Undercurl support, true color, extended keys
- Splits: `|` horizontal, `-` vertical, `v`/`s` (open in cwd)

### fzf.nix

Fzf with custom options, fd integration, ripgrep.

- Default options: 60% height, reverse layout, highlight line, custom colors
- `fd` as the file finder (hidden, follow symlinks)
- `fzf-preview` for previews
- `nsearch-adv` package
- `Ctrl+R` history, `Ctrl+Space` accept autosuggestion (wired in zsh init)
- `fzfp` alias for fzf with preview

### starship.nix

Custom starship prompt with git icons, file/folder counts, nix shell indicator.

- Shows: directory icon, file count, folder count, disk usage
- Git: branch, host icon (github/gitlab/etc), last commit message, status with counts
- Two-line prompt (git info on second line)
- Vim mode character (`vimcmd_symbol`)
- Nix shell state indicator (impure/pure/unknown)

### git.nix

Git + gh + lazygit.

- `pull.rebase = true`, `merge.conflictStyle = "diff3"`, `rerere.enabled`
- `init.defaultBranch = "master"`, `core.editor = "nvim"`
- `gh` with `gh-notify` extension
- `lazygit` with nvim-remote edit preset, OSC52 clipboard
- `gfm <branch> [remote]` helper (fetch + merge)
- `git-addnospace` alias (stage ignoring whitespace)
- Git maintenance enabled for `~/work/nixpkgs`

### bat.nix

- `bat` enabled
- `cat` aliased to `bat --paging=never --style=plain`

### btop.nix

- `btop` with `vim_keys = true`, transparent background

### direnv.nix

- `direnv` + `nix-direnv`, silent, zsh integration

### eza.nix

- `eza` with colors, git, icons, group/header/smart-group
- Aliases: `ls` → `eza -s modified --reverse`, `lt`/`tree` → tree view

### zoxide.nix

- `zoxide` with `--cmd cd` (replaces `cd` with zoxide)
- Excludes `/nix`

### jq.nix

- `jq` enabled

### sesh.nix

[sesh](https://github.com/joshmedeski/sesh) tmux session manager.

- Pinned to v2.25.0 (overridden hash)
- `tmuxKey = "c-o"` (open sesh from tmux)
- Predefined sessions: `todo` (opens todo.md in nvim), `notes` (ObsidianQuickSwitch), `LeetCode` (Leet command), `main`
- Blacklist: scratch, Library, Applications, Pictures
- `Ctrl+p` in tmux → `sesh last`

### aliases.nix

Shell aliases + the `nxbuild` helper.

- Aliases: `c` (clear), `d` (background), `cp`/`rm`/`rcp` (colored/verbose), `mkdir -pv`, `isodate`, `matrix`, `fetch` (fastfetch), `font-family`
- `help` command (pipes `--help` through bat)
- **`nxbuild`** - build nix packages on remote builders. Usage:
  ```bash
  nxbuild semi .#iso          # ad-hoc builder
  nxbuild .#iso               # configured builders
  nxbuild dsd -j 4 nixpkgs#hello
  ```

### android.nix

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

Auto-imported directory (`modules/home/ai/`), excluding `combined-system-prompt.nix` (a helper). Import via `homeModules.ai`.

Sets `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = 1` globally.

### opencode/

[Opencode](https://github.com/leohenon/opencode-vim) agent configuration.

- Package: `pkgs.opencode-vim` (patched node_modules hash + bun version check bypass)
- Default agent: `OpenAgent` with the combined system prompt
- Plugin: ponytail (lazy dev skill)
- TUI: vim system clipboard, `jk` escape, enter-to-submit, insert-after-submit
- Skills: local (`git-wisdom`, `think-deeper`), ponytail suite, frontend-design (from claude-code)
- Registry: wires openagents-control "developer" profile components to `~/.config/opencode/`
- Providers are defined in `providers/` (see below), not inline

### claude.nix

[Claude Code](https://claude.ai/code).

- `programs.claude-code.enable` + MCP integration
- Vim mode, model `claude-opus-4-6`, `ENABLE_TOOL_SEARCH = true`
- `~/.claude/CLAUDE.md` set to the combined system prompt

### mcp.nix

MCP (Model Context Protocol) servers. All set to `lifecycle = "eager"`.

| Server | Type | Purpose |
|---|---|---|
| `git` | command | Git MCP server |
| `fetch` | command | Fetch MCP server |
| `sequential-thinking` | command | Chain-of-thought reasoning |
| `github` | command | GitHub API (needs `GITHUB_TOKEN`) |
| `everything` | command | Filesystem access to home dir |
| `gitnexus` | command | Code knowledge graph |
| `playwright` | command | Browser automation |
| `newton-hs-prod` | http | Juspay internal code search |
| `deepwiki` | remote | DeepWiki docs |
| `nixos` | command | NixOS MCP (runs `mcp-nixos`) |

### pi.nix

[Pi coding agent](https://github.com/anthropics/pi) (via `llm-agents`).

- Default provider: anthropic, thinking level: medium
- `vim-motions-pi` package with `jk` escape + OSC52 clipboard
- Packages: nodejs, bun, copy
- System prompt: combined system prompt

### providers/

Auto-imported directory of opencode provider definitions. One file per provider, drop a new `.nix` to add a provider.

- `anthropic.nix` - built-in Anthropic (env `ANTHROPIC_API_KEY`), models: claude-opus-4-7 ("gawwd"), claude-sonnet-4-6 ("worker"), claude-haiku-4-5 ("haiya")
- `office.nix` - shared Juspay LLM provider (litellm, `@ai-sdk/openai-compatible`), used by both opencode and pi. Default model `litellm/open-large`, explore agent uses `open-fast`. 13 models: open-large/fast/vision, claude-opus/sonnet, glm, gemini, minimax, kimi
- `zen.nix` - opencode Zen gateway (`provider.opencode`, built-in, env `OPENCODE_API_KEY`). Free models work without a key; with a key all 71 models load
- `openrouter.nix` - OpenRouter (`provider.openrouter`, built-in, env `OPENROUTER_API_KEY`)

### combined-system-prompt.nix

A helper (not a module) - combines numbered markdown files in `system-prompts/` (01-git, 02-before-you-code, 03-code-comments) into a single prompt string. Used by claude.nix, pi.nix, and opencode. Ponytail lives as a toggleable plugin, not a static prompt.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.homeModules.ai ];
  # opencode + claude + mcp + pi + providers
}
```

---

## browser

Auto-imported directory. Import via `homeModules.browser`.

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

- Both platforms: google-chrome, telegram-desktop
- Darwin: mas, bruno, ytmdesktop
- nixcord: Discord client with messageLogger, showMeYourName, fakeNitro plugins

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
