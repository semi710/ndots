> [!NOTE]
> **Welcome!**
>
> This is the main branch of my Nix configuration. For the fully riced version with Hyprland/Wayland, see the **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)**.

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
| **Darwin** | nix-darwin on MacBook Pro (Yabai + skhd) |
| **Build System** | Flakes + Flake-Parts + nix-wire auto-wiring |
| **Disk Management** | disko for declarative partitioning |
| **Secrets** | sops-nix |

---

## Hosts

| Host | Platform | Description |
|------|----------|-------------|
| **mach** | NixOS | Personal laptop |
| **dsd** | NixOS | Work desktop |
| **semi** | NixOS | Semi-personal machine |
| **virt** | NixOS | VM testing |
| **anywhere** | NixOS | Generic QEMU guest template |
| **iso** | NixOS | Installer ISO (see below) |
| **jp-mbp** | Darwin | MacBook Pro M4 |

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
├── hosts/              # Host configurations
│   ├── nixos/          # NixOS machines
│   │   ├── mach/
│   │   ├── dsd/
│   │   ├── semi/
│   │   ├── virt/
│   │   └── anywhere/
│   ├── iso/
│   │   └── iso/        # Installer ISO config
│   ├── darwin/
│   │   └── jp-mbp/     # MacBook Pro
│   └── home/           # Home-manager user profiles
├── modules/
│   ├── nixos/          # NixOS system modules
│   ├── darwin/         # Darwin system modules
│   ├── home/           # Home-manager modules
│   └── flake/          # Flake-level modules (nix config, caches)
├── packages/           # Custom packages
│   ├── copy.nix        # OSC52 clipboard utility
│   ├── aria2tui.nix    # TUI for aria2
│   └── ...
├── templates/          # Project templates (go, node, python)
├── parts/              # Flake-Parts modules
│   ├── disko/          # Partitioning schemas
│   └── default.nix
├── overlays/           # Nixpkgs overlays
├── config.nix          # Shared user/builder config
└── flake.nix           # Entry point
```

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

- **Declarative disk partitioning** with disko
- **Encrypted secrets** via sops-nix
- **Custom packages**: `copy` (OSC52), `aria2tui`, `sklauncher`, etc.
- **Project templates**: Go, Node.js, Python with treefmt + pre-commit hooks
- **Binary caches**: Configured for nixos.org, nix-community, and personal caches

---

## Related

- **[Utils](https://github.com/niksingh710/utils)** - Utility scripts and tools
- **[nvix](https://github.com/semi710/nvix)** - Neovim configuration (used here)
- **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)** - Full ricing with Hyprland/Wayland

### Acknowledgments

Thanks to all the amazing NixOS community members whose configurations inspired this setup:
[iynaix](https://github.com/iynaix), [fufexan](https://github.com/fufexan), [nobbZ](https://github.com/nobbZ), [lilleaila](https://github.com/lilleaila), [vimjoyer](https://github.com/vimjoyer), [srid](https://github.com/srid)
