# Building an ISO

A minimal (~2.2 GB) install ISO with a pre-configured shell environment.

## Pre-built ISOs

Automated CI builds via GitHub Actions:

| Architecture | Runner |
|-------------|--------|
| `x86_64-linux` | `ubuntu-latest` |
| `aarch64-linux` | `ubuntu-24.04-arm` |

Download from [Actions artifacts](https://github.com/semi710/ndots/actions/workflows/iso.yml) (90-day retention).

## Build Locally

```bash
just iso
# or
nix build .#iso
# ISO at: result/iso/
```

## What's Included

- **Shell**: zsh + vi-mode + autosuggestions + syntax-highlighting
- **Tools**: nvim (bare), tmux, fzf, fd, ripgrep, eza, zoxide, bat, btop
- **Clipboard**: OSC52 copy support (works over SSH)
- **Prompt**: starship
- **Network**: NetworkManager + OpenSSH
- **User**: `nixos` / password: `nixos`
- **Disk**: `disko` for partitioning

## Using the ISO

1. Flash to a USB drive:
   ```bash
   sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
   ```

2. Boot from USB
3. Follow [Installation](installation.md)
