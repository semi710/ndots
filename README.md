<p align="center" style="color:grey">

![banner](https://github.com/user-attachments/assets/1f1600e9-a1d9-4aa6-9035-5d19e4ece908)

<div align="center">

<small><small>**[gdots](https://github.com/niksingh710/gdots) + [cdots](https://github.com/niksingh710/cdots)**</small>

</div>

<div align="center">
<table>
<tbody>
<td align="center">
<img width="2000" height="0"><br>

My **[NixOS](https://nixos.org) + [nix-darwin](https://github.com/LnL7/nix-darwin)** configuration built with flakes.<br>
Modularized via **[Flake-Parts](https://flake.parts)** and auto-wired with **[nix-wire](https://github.com/semi710/nix-wire)**.<br>
<small>**Fully CLI-based** — accessed via SSH + Tailscale</small><br>

![GitHub repo size](https://img.shields.io/github/repo-size/niksingh710/ndots)
![GitHub Org's stars](https://img.shields.io/github/stars/niksingh710%2Fndots)
![GitHub forks](https://img.shields.io/github/forks/niksingh710/ndots)
![GitHub last commit](https://img.shields.io/github/last-commit/niksingh710/ndots)

## Star History

<a href="https://www.star-history.com/?repos=semi710%2Fndots&type=date&logscale&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=semi710/ndots&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=semi710/ndots&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=semi710/ndots&type=date&legend=top-left" />
 </picture>
</a>

<img width="2000" height="0">
</td>
</tbody>
</table>
</div>
</p>

---

## Architecture

| Platform | Details |
|----------|---------|
| **Linux** | NixOS hosts, fully CLI-based |
| **Darwin** | nix-darwin on MacBook Pro (Yabai + skhd / Aerospace) |
| **Build System** | Flakes + Flake-Parts + nix-wire auto-wiring |
| **Disk Management** | disko for declarative partitioning |
| **Secrets** | sops-nix (age encryption, split by office/server keys) |
| **Networking** | Tailscale mesh VPN for all hosts |
| **Monitoring** | Beszel hub + agents on all NixOS hosts |
| **Deployment** | `just deploy` (auto-detects NixOS vs Darwin) |

---

## Hosts

| Host | Platform | Arch | CPU | RAM | Role | Services |
|------|----------|------|-----|-----|------|----------|
| **mach** | NixOS | x86_64 | Intel i7-10510U (4c/8t) | 24 GB | Personal laptop | FileBrowser, Beszel agent, Tailscale, Docker |
| **dsd** | NixOS | x86_64 | Intel i9-12900KS (16c/24t) | 64 GB | Intel i9-12900KS | FileBrowser, Beszel agent, Tailscale, Docker |
| **semi** | NixOS | x86_64 | Intel i9-14900K (24c/32t) | 128 GB | Intel i9-14900K | FileBrowser, Beszel agent, Tailscale, Docker |
| **obox** | NixOS | aarch64 | Ampere Neoverse-N1 (4c/4t) | 24 GB | Oracle Cloud VPS | Beszel hub, Stirling PDF, FileBrowser, Caddy, Tailscale, Docker |
| **virt-x86_64** | NixOS | x86_64 | — | — | VM testing | — |
| **virt-aarch64** | NixOS | aarch64 | — | — | VM testing | — |
| **anywhere** | NixOS | — | — | — | Generic QEMU guest template | — |
| **iso** | NixOS | — | — | — | Installer ISO | — |
| **jp-mbp** | Darwin | aarch64 | Apple M4 | — | MacBook Pro | Yabai/skhd, Aerospace, Karabiner, Hammerspoon |

---

## Services

### Beszel Monitoring

Hub on **obox**, agents on all NixOS hosts. System + Docker stats, SSH key-based agent registration, universal token for auto-enrollment.

### Stirling PDF

On **obox**, branded as "semi.sh PDF". NixOS native service, no Docker. Update notifications disabled. Behind Caddy reverse proxy.

### FileBrowser Quantum

On **all NixOS hosts**. Runs as root for full filesystem access. Tailscale-only (no public firewall). Admin credentials per-host via sops — user is hostname, password is `<host>@filebrowser`.

### Caddy

On **obox**. Imperative config (`/etc/caddy/Caddyfile`) — editable on the box, no rebuild needed.

### Syncthing

Home-manager module, syncs `.notes` and `.dump` folders across all 4 devices.

---

## Quick Install

Boot from the [pre-built ISO](#iso-installer) or use upstream NixOS minimal ISO.

1. **Connect to the internet**
   ```bash
   nmtui  # WiFi via NetworkManager
   ```

2. **Get the disko configuration**
   ```bash
   # Replace <hostname> with your target (e.g., mach, dsd, semi, virt)
   nix eval github:semi710/ndots#disko.partition \
     --apply 'b: builtins.fromJSON (builtins.toJSON (b { device = "/dev/nvme0n1"; ssdOptions = []; }))' \
     --impure > disko-config.nix
   ```

3. **Partition the disk**
   ```bash
   sudo disko --mode destroy,format,mount --yes-wipe-all-disks ./disko-config.nix
   ```

4. **Install the system**
   ```bash
   sudo nixos-install --no-root-passwd --root /mnt --flake github:semi710/ndots#<hostname>
   ```

> [!NOTE]
> If you want to set a root password during install (recommended), omit `--no-root-passwd`:
> ```bash
> sudo nixos-install --root /mnt --flake github:semi710/ndots#<hostname>
> ```
> After setting your user password, lock root for security:
> ```bash
> sudo passwd -l root
> ```

---

## Deployment

All deployment is handled via `just` recipes:

```bash
just deploy              # Current host (auto-detects NixOS vs Darwin)
just deploy obox         # Remote deploy to obox (builds on obox)
just deploy mach         # Remote deploy to mach
just deploy dsd          # Remote deploy to dsd
just deploy semi         # Remote deploy to semi
just home nikhil         # Home-manager only (run on target machine)
```

Other commands:

```bash
just build <host>        # Dry build (eval only)
just iso                 # Build installer ISO
just fmt                 # Format nix files (treefmt)
just update              # Update flake lock
just check               # Check flake (eval all configs)
just gc                  # Garbage collect all profiles
```

---

## Adding a New Host (nixos-anywhere)

The `anywhere` template is a generic NixOS server config for bootstrapping new machines via SSH — no physical access or ISO needed.

1. **Copy the template**
   ```bash
   cp -r hosts/nixos/anywhere hosts/nixos/<name>
   ```

2. **Set the platform arch** in `hosts/nixos/<name>/default.nix`:
   ```nix
   nixpkgs.hostPlatform = "x86_64-linux"; # or "aarch64-linux"
   ```

3. **Adjust disk config** in `hosts/nixos/<name>/disk.nix` — set the correct device path.

4. **Install via nixos-anywhere** (from any machine with nix + SSH access):
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --generate-hardware-config nixos-generate-config ./hosts/nixos/<name>/hardware.nix \
     --flake .#<name> \
     --target-host root@<ip>
   ```

   This partitions the disk, installs the system, and reboots — fully unattended.

5. **Deploy future updates** with:
   ```bash
   just deploy <name>
   ```

> The template uses the `virt` user from `config.nix`. Override with a real user for production hosts. Add sops, tailscale, beszel, etc. by importing the relevant modules.

---

## ISO Installer

A minimal (~2.2 GB) install ISO with a pre-configured shell environment.

### Pre-built ISOs

Automated CI builds for both architectures via GitHub Actions:

| Architecture | Status |
|-------------|--------|
| `x86_64-linux` | Built on `ubuntu-latest` |
| `aarch64-linux` | Built on `ubuntu-24.04-arm` |

Download the latest ISO from the [Actions artifacts](https://github.com/semi710/ndots/actions/workflows/iso.yml) (90-day retention).

### What's Included

- **Shell**: zsh + vi-mode + autosuggestions + syntax-highlighting
- **Tools**: nvim (bare), tmux, fzf, fd, ripgrep, eza, zoxide, bat, btop
- **Clipboard**: OSC52 copy support (works over SSH)
- **Prompt**: starship
- **Network**: NetworkManager + OpenSSH
- **User**: `nixos` / password: `nixos`
- **Disk**: `disko` for partitioning

### Build Locally

```bash
nix build .#iso
# ISO at: result/iso/
```

---

## Repository Structure

```
.
├── hosts/                  # Host configurations
│   ├── nixos/
│   │   ├── common/
│   │   │   └── workstation.nix   # Shared workstation config (semi, dsd)
│   │   ├── mach/                 # Personal laptop
│   │   ├── dsd/                  # Work desktop
│   │   ├── semi/                 # Semi-personal machine
│   │   ├── obox/                 # Oracle Cloud VPS (aarch64)
│   │   ├── virt-x86_64/          # VM testing
│   │   ├── virt-aarch64/         # VM testing
│   │   └── anywhere/             # Generic QEMU guest template
│   ├── iso/
│   │   └── iso/                  # Installer ISO config
│   └── darwin/
│       └── jp-mbp/               # MacBook Pro M4
├── modules/
│   ├── nixos/                    # NixOS system modules
│   │   ├── beszel.nix            # Beszel agent module
│   │   ├── filebrowser.nix       # FileBrowser Quantum module
│   │   ├── virtualisation.nix    # Shared docker + podman module
│   │   ├── tailscale.nix         # Tailscale VPN module
│   │   ├── hardware/             # Audio, bluetooth, etc.
│   │   ├── hyprland/             # Hyprland window manager
│   │   ├── juspay/               # Juspay workspace config
│   │   └── ...
│   ├── darwin/                   # Darwin system modules
│   │   ├── yabai/                # Tiling WM + skhd
│   │   ├── brew.nix              # Homebrew casks/formulae
│   │   ├── stylix.nix            # Theming
│   │   └── ...
│   ├── home/                     # Home-manager modules
│   │   ├── ai/                   # AI tooling (opencode, claude, mcp)
│   │   │   ├── opencode/         # Opencode config (default, skills, registry)
│   │   │   └── skills/           # Shared skills (git-wisdom, think-deeper)
│   │   ├── shell/                # zsh, tmux, fzf, starship, git, etc.
│   │   ├── editor/               # Helix, nvix (Neovim)
│   │   ├── browser/              # Zen browser
│   │   ├── terminal/             # Kitty
│   │   ├── hyprland/             # Hyprland home config
│   │   ├── darwin/               # Aerospace, Karabiner, Hammerspoon
│   │   ├── syncthing.nix         # Cross-device file sync
│   │   ├── sops.nix              # Home-level secrets
│   │   └── ...
│   └── flake/                    # Flake-level modules (nix config, caches)
├── packages/                     # Custom packages
│   ├── copy.nix                  # OSC52 clipboard utility
│   ├── aria2tui.nix              # TUI for aria2
│   ├── sklauncher.nix            # Minecraft launcher
│   ├── stremio-enhanced.nix      # Stremio with addons
│   └── ...
├── templates/                    # Project templates (go, node, python)
├── parts/                        # Flake-Parts modules
│   ├── disko/                    # Partitioning schemas (btrfs, btrfs-enc)
│   └── default.nix
├── overlays/                     # Nixpkgs overlays
├── secrets/                      # sops-encrypted secrets
│   ├── office.yaml               # Office machines (semi, dsd)
│   └── server.yaml               # Servers (obox, mach)
├── config.nix                    # Shared user/builder config
├── .sops.yaml                    # sops creation rules
├── justfile                      # Deployment commands
└── flake.nix                     # Entry point
```

---

## Secrets

Managed with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption. Two key groups:

| File | Key | Hosts | Contents |
|------|-----|-------|----------|
| `secrets/office.yaml` | office age key | semi, dsd | Tailscale auth, nix access token, syncthing certs, filebrowser passwords |
| `secrets/server.yaml` | office age key | obox, mach | Tailscale auth, beszel creds/SSH key, filebrowser passwords |
| `secrets/keys.yaml` | personal age key | — | Age key generation |

---

## Flake Outputs

```bash
# Build ISO for current architecture
nix build .#iso

# Build a specific host (e.g., mach)
nixos-rebuild switch --flake .#mach

# Build darwin host (e.g., jp-mbp)
darwin-rebuild switch --flake .#jp-mbp

# Activate home configuration
home-manager switch --flake .#<user>

# Run checks
nix flake check

# Enter dev shell
nix develop
```

---

## Key Features

- **Declarative disk partitioning** with disko (btrfs encrypted)
- **Encrypted secrets** via sops-nix, split by office/server keys
- **Tailscale mesh VPN** across all hosts
- **Beszel monitoring** — hub on obox, agents on all NixOS hosts
- **FileBrowser Quantum** — full filesystem access, Tailscale-only
- **Stirling PDF** — self-hosted PDF tools, branded
- **Caddy** reverse proxy on obox (imperative config)
- **Syncthing** — cross-device file sync via home-manager
- **Custom packages**: `copy` (OSC52), `aria2tui`, `sklauncher`, `stremio-enhanced`
- **Project templates**: Go, Node.js, Python with treefmt + pre-commit hooks
- **Binary caches**: Configured for nixos.org, nix-community, and personal caches
- **AI tooling**: Opencode with shared skills, Claude Code, MCP servers

---

## Related

- **[Utils](https://github.com/niksingh710/utils)** - Utility scripts and tools
- **[nvix](https://github.com/semi710/nvix)** - Neovim configuration (used here)
- **[nix-wire](https://github.com/semi710/nix-wire)** - Flake auto-wiring library
- **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)** - Full ricing with Hyprland/Wayland

### Acknowledgments

Thanks to all the amazing NixOS community members whose configurations inspired this setup:
[iynaix](https://github.com/iynaix), [fufexan](https://github.com/fufexan), [nobbZ](https://github.com/nobbZ), [lilleaila](https://github.com/lilleaila), [vimjoyer](https://github.com/vimjoyer), [srid](https://github.com/srid)
