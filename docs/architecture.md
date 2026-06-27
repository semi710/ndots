# Architecture

## Flake Structure

The entire configuration is a single flake, auto-wired by [nix-wire](https://nix-wire.semi.sh) <a href="https://github.com/semi710/nix-wire" target="_blank"><sub>:fontawesome-brands-github:</sub></a>:

```nix
# flake.nix (simplified)
{
  inputs = { nixpkgs, nixpkgs-stable, nix-wire, flake-parts, home-manager, ... };
  outputs = inputs: inputs.nix-wire.mkFlake {
    inherit inputs;
    imports = [ ./parts ];
  };
}
```

```
flake.nix
  └── nix-wire.mkFlake
        ├── parts/default.nix            # Flake-Parts: treefmt, devShells, pre-commit, disko
        ├── perSystem                    # devShells.default, treefmt, pre-commit
        ├── flake.nixosModules.*         # auto-wired from modules/nixos/*
        ├── flake.homeModules.*          # auto-wired from modules/home/*
        ├── flake.darwinModules.*        # auto-wired from modules/darwin/*
        ├── flake.flakeModules.nix       # shared nix settings (from modules/flake/nix/*)
        ├── nixosConfigurations.*         # auto-wired from hosts/nixos/*/
        ├── darwinConfigurations.*       # auto-wired from hosts/darwin/*/
        └── legacyPackages.*.homeConfigurations.*  # from hosts/home/*
```

## nix-wire Auto-wiring

[nix-wire](https://nix-wire.semi.sh) <a href="https://github.com/semi710/nix-wire" target="_blank"><sub>:fontawesome-brands-github:</sub></a> auto-imports modules and host configs based on directory conventions:

| Source path | Flake output |
|---|---|
| `modules/nixos/<name>/default.nix` (or `<name>.nix`) | `nixosModules.<name>` |
| `modules/home/<name>/default.nix` (or `<name>.nix`) | `homeModules.<name>` |
| `modules/darwin/<name>/default.nix` (or `<name>.nix`) | `darwinModules.<name>` |
| `modules/flake/nix/*.nix` | composed into `flakeModules.nix` |
| `hosts/nixos/<name>/default.nix` | `nixosConfigurations.<name>` |
| `hosts/darwin/<name>/default.nix` | `darwinConfigurations.<name>` |
| `hosts/home/<user>.nix` | `homeConfigurations.<user>` |
| `hosts/iso/<name>/default.nix` | ISO build (`nix build .#iso`) |

Directories with a `default.nix` are auto-imported. The helper `inputs.nix-wire.lib.autoImport ./.` imports every `.nix` file and `default.nix` in a directory. `autoImportExcept` is used where specific files need exclusion (e.g. the AI module excludes `combined-system-prompt.nix`, which is a helper not a module).

!!! note "Host name auto-set"
    `nix-wire` automatically sets `networking.hostName = <dir-name>` for each NixOS host from its directory name. You don't set it manually.

## Module Layering

```
modules/
  nixos/
    default.nix          # base system: imports flakeModules.nix, stylix, homeModules.default; nix-ld, envfs, base packages
    beszel.nix           # monitoring agent
    filebrowser.nix      # FileBrowser Quantum service (custom options)
    virtualisation.nix   # docker (system+rootless) + podman
    tailscale.nix        # mesh VPN (just enables the service)
    intel.nix            # Intel graphics + microcode
    stylix.nix            # wires stylix NixOS module + home stylix config
    hardware/            # audio (pipewire), bluetooth, touchpad
    hyprland/            # Hyprland WM + home imports + rofi overlays
    juspay/              # Juspay workspace: shared-config, workspace (postgres+redis)
    minecraft/           # Minecraft server: paper, plugins, users
  home/
    default.nix          # base home: shell, editor, ssh, nix-index, aria2, fonts
    shell/               # zsh, tmux, fzf, starship, git, bat, btop, direnv, eza, zoxide, jq, sesh, aliases, android
    editor/              # helix, nvix (Neovim via nvix flake)
    ai/                  # opencode, claude, mcp, pi, providers/, combined-system-prompt
    browser/             # Zen browser (base, extensions, keymaps, search)
    terminal/            # kitty
    hyprland/            # Hyprland home config, rofi, hypridle, hyprlock, keymaps, monitor, rules
    darwin/              # aerospace, karabiner, hammerspoon, jankyborders
    stylix/              # theming config + cli-only mode
    syncthing.nix, sops.nix, ssh.nix, packages.nix, mpv.nix, zathura.nix, aria2.nix, nix-index.nix, nix-conf-fix.nix, home-only.nix
  darwin/
    default.nix          # base darwin: imports flakeModules.nix, settings, brew, stylix, sharedModules
    settings/            # system.nix (macOS defaults), builder.nix (linux-builder)
    yabai/               # yabai WM + skhd keybindings
    brew.nix             # Homebrew casks/formulae/mas
    stylix.nix            # wires stylix darwin module + home stylix config
    sharedModules.nix    # shared home-manager modules for darwin (default, packages, terminal, mpv, zathura, browser)
  flake/
    nix/                 # nix.nix (latest nix, gc, registry), caches.nix (substituters)
```

## How Hosts Inherit

Each host `default.nix` imports the modules it needs. There is **no forced inheritance** - each host explicitly lists its imports. This gives full control per host.

### Workstation pattern (semi, dsd)

`hosts/nixos/common/workstation.nix` is the shared base for Juspay work machines. It imports:

```nix
imports = [
  flake.nixosModules.default       # base system
  flake.nixosModules.juspay        # workspace config (zsh, openssh, docker, tailscale, timezone)
  flake.inputs.sops-nix.nixosModules.sops
  flake.inputs.disko.nixosModules.disko
  flake.nixosModules.beszel
  flake.nixosModules.tailscale
  flake.nixosModules.virtualisation
  flake.nixosModules.filebrowser
];
```

Then each host adds only its specifics:

```nix
# hosts/nixos/semi/default.nix
imports = [ ../common/workstation.nix ./disk.nix ./hardware.nix ./extra-users.nix ];

# hosts/nixos/dsd/default.nix
imports = [ ../common/workstation.nix ./disk.nix ./hardware.nix ./extra-users.nix flake.nixosModules.minecraft ];
```

### Standalone hosts (mach, obox, anywhere)

These define all imports directly in their `default.nix`. They are self-contained.

### Darwin hosts (jp-mbp)

```nix
imports = [
  flake.darwinModules.default   # base: settings, brew, stylix, sharedModules
  flake.darwinModules.yabai     # window manager + skhd
  flake.inputs.sops-nix.darwinModules.sops
];
```

## The `hm` Shorthand

Most hosts use a `mkAliasOptionModule` to create the `config.hm` shorthand:

```nix
lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" <username> ]
```

So `config.hm.programs.zsh.enable` is equivalent to `config.home-manager.users.<username>.programs.zsh.enable`. This keeps per-host home-manager config concise.

## Overlays

Overlays live in `overlays/` and are composed automatically:

```
overlays/
  default.nix     # composes all overlays via lib.composeManyExtensions
  packages.nix    # exposes custom packages + stable nixpkgs + external overlays
```

`overlays/default.nix` composes:
1. `overlays/packages.nix` - local custom packages (from `packages/`), `stable` nixpkgs, `nsearch-adv`, `opencode-vim` (with patched hashes), `appstream` Darwin fix
2. `inputs.llm-agents.overlays.default` - AI agent tooling

The overlay is applied globally via `nix-wire` so `pkgs.copy`, `pkgs.road-rage`, `pkgs.stremio-enhanced`, etc. are available everywhere.

!!! tip "Accessing custom packages"
    After the overlay, these are available as `pkgs.<name>`:
    `copy`, `aria2tui`, `sklauncher`, `stremio-enhanced`, `airsync`, `hammerspoon`, `skhd-zig`, `road-rage`, `stable` (nixpkgs-stable), `nsearch-adv`, `putils` (utils flake), `opencode-vim`.

## How Packages Are Exposed

`nix-wire` auto-discovers `packages/*.nix` and exposes them as `self.packages.${system}.<name>`. The overlay in `overlays/packages.nix` then re-exposes them into `pkgs`:

```nix
# overlays/packages.nix (simplified)
selfPkgs = self.packages.${final.stdenv.hostPlatform.system};
in {
  copy = selfPkgs.copy;
  aria2tui = selfPkgs.aria2tui;
  # ...
}
```

So a package defined in `packages/copy.nix` becomes available as both:
- `nix run .#copy` (flake output)
- `pkgs.copy` (via overlay, in any module)

## The Justfile

The [`justfile`](https://github.com/casey/just) provides deployment and maintenance commands:

| Command | What it does |
|---|---|
| `just deploy` | Deploy to current host (auto-detects NixOS vs Darwin) |
| `just deploy <host>` | Remote deploy over SSH (builds on target) |
| `just home [user]` | Home-manager only switch (run on target machine) |
| `just build <host>` | Dry build (eval only, no compilation) |
| `just iso` | Build installer ISO (`nix build .#iso`) |
| `just doc` | Serve docs locally on a random port |
| `just fmt` | Format nix files with treefmt |
| `just update` | Update flake lock |
| `just check` | `nix flake check` (eval all configs) |
| `just gc` | Garbage collect all profiles (`nh clean all`) |

The `deploy` command auto-detects platform: Darwin runs `nh darwin switch . -H jp-mbp`, NixOS runs `nh os switch .`. Remote hosts use `--target-host` + `--elevation-strategy passwordless`.

## .sops.yaml Structure

Secrets are encrypted with [age](https://age-encryption.org/) via [sops-nix](https://github.com/Mic92/sops-nix). The `.sops.yaml` defines which age key encrypts which file:

```yaml
keys:
  - &personal age1qq74n2h6sq8gv843dc67k3jczru768pq6jg3zg4ycmrtqdyfhfes803ncy
  - &office   age1kkh7046u0m22jsw9cclsdlefxyzlmpxhwm58n3qjrjshjqn2lq5qey6p7e
creation_rules:
  - path_regex: ^secrets/keys\.yaml$
    key_groups:
      - age: [*personal]
  - path_regex: ^secrets/(office|server)\.yaml$
    key_groups:
      - age: [*office]
```

| File | Age key | Hosts | Contents |
|---|---|---|---|
| `secrets/office.yaml` | office | semi, dsd | Tailscale auth, nix access token, syncthing certs, filebrowser passwords |
| `secrets/server.yaml` | office | obox, mach | Tailscale auth, beszel creds/SSH key, filebrowser passwords |
| `secrets/keys.yaml` | personal | - | User password, tokens (github, cachix, nix-access, ai/*), SSH keys, syncthing certs, rclone config |

!!! note "Same key, separate files"
    Both `office.yaml` and `server.yaml` use the office age key. The split is about **trust boundaries** (work context vs infrastructure), not key separation.

## config.nix

The root `config.nix` holds shared user and builder data (not a NixOS module - it's plain nix imported with `import (flake + "/config.nix")`):

```nix
{
  users.me   = { username, fullname, email, sshPublicKeys };
  users.jp   = { username, fullname, email, sshPublicKeys };  # Juspay identity
  users.virt = { username, fullname, email, sshPublicKeys, hashedPassword };  # VM/template
  builders.key  = { publicKey };  # shared SSH builder key
  builders.linux = { system, maxJobs, speedFactor, supportedFeatures, sshUser };  # defaults
  builders.dsd   = linux // { hostName, hostNames, hostPublicKey };
  builders.semi   = linux // { hostName, hostNames, hostPublicKey };
}
```

Hosts compose their user from this. Workstations override `username` to `nikhil.singh` (the Juspay identity).

## Deployment Flow

```
just deploy <host>
  → nh os switch .#<host> --target-host <user>@<host>
    → nix builds the system closure (on target)
    → activates the new generation
    → sops decrypts secrets to /run/secrets/
    → services start with secrets wired
```

## Flake Inputs

Key inputs and their purpose:

| Input | Purpose |
|---|---|
| `nixpkgs` | Unstable nixpkgs (primary) |
| `nixpkgs-stable` | NixOS 25.05 (for `pkgs.stable` overlay) |
| `nix-wire` | Auto-wiring of modules/hosts |
| `flake-parts` | Flake-Parts module system |
| `treefmt-nix` | Code formatting |
| `git-hooks` | Pre-commit hooks |
| `home-manager` | Home directory management |
| `nix-darwin` | macOS system management |
| `sops-nix` | Secrets management |
| `stylix` | Cross-platform theming |
| `disko` | Declarative disk partitioning |
| `nix-cachyos-kernel` | CachyOS kernel overlay |
| `hyprland` | Hyprland window manager |
| `minecraft` | nix-minecraft (Paper server) |
| `zen-browser` | Zen browser flake |
| `firefox-addons` | Firefox extension packaging |
| `nix-index-database` | `,` command (run unknown binaries) |
| `nvix` | Neovim configuration (personal flake) |
| `nsearch` | Nix search tool (personal flake) |
| `utils` | Utility scripts (personal flake) |
| `llm-agents` | AI agent tooling (gitnexus, pi) |
| `opencode-vim` | Opencode editor (patched) |
| `claude-code` | Claude Code (vendored for skills) |
| `ponytail` | Lazy dev skill (vendored) |
| `openagents-control` | Agent registry profiles (vendored) |
