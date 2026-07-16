# ndots

A declarative **NixOS + nix-darwin** configuration built with [flakes](https://nixos.wiki/wiki/Flakes), modularized via [Flake-Parts](https://flake.parts), and auto-wired with [nix-wire](https://nix-wire.semi.sh) <a href="https://github.com/semi710/nix-wire" target="_blank">:fontawesome-brands-github:</a>.

Utilities and scripts from [utils](https://utils.semi.sh) <a href="https://github.com/semi710/utils" target="_blank">:fontawesome-brands-github:</a>.

Fully CLI-based - all hosts are managed via SSH + Tailscale. No GUI required for administration.

## At a Glance

| | |
|---|---|
| **Platforms** | NixOS (Linux), nix-darwin (macOS) |
| **Build System** | Flakes + Flake-Parts + nix-wire |
| **Disk Management** | disko (declarative partitioning) |
| **Secrets** | sops-nix (age encryption) |
| **Networking** | Tailscale mesh VPN |
| **Monitoring** | Beszel hub + agents |
| **Deployment** | `just deploy` (auto-detects NixOS vs Darwin) |
| **Theming** | Stylix (kanagawa-dragon, cross-platform) |

## Hosts

| Host | CPU | RAM | Role |
|------|-----|-----|------|
| **mach** | Intel i7-10510U (4c/8t) | 24 GB | Personal laptop |
| **dsd** | Intel i9-12900KS (16c/24t) | 64 GB | Work desktop |
| **semi** | Intel i9-14900K (24c/32t) | 128 GB | Semi-personal |
| **obox** | Ampere Neoverse-N1 (4c/4t) | 24 GB | Oracle Cloud VPS |
| **jp-mbp** | Apple M4 | - | MacBook Pro |

See [Hosts](hosts/index.md) for per-host details.

## Services

- [Beszel](services/beszel.md) - system monitoring hub + agents
- [Stirling PDF](services/stirling-pdf.md) - self-hosted PDF tools
- [FileBrowser Quantum](services/filebrowser.md) - web file manager
- [Caddy](services/caddy.md) - reverse proxy
- [naste](services/naste.md) - self-hosted paste service
- [Syncthing](services/syncthing.md) - cross-device file sync
- [Tailscale](services/tailscale.md) - mesh VPN
- [Docker & Podman](services/docker.md) - container runtimes

## Modules

The flake exposes reusable modules you can import into your own configuration:

- [NixOS Modules](modules/nixos.md) - system services, hardware, window manager
- [Home Modules](modules/home.md) - shell, editor, AI, browser, terminal, theming
- [Darwin Modules](modules/darwin.md) - macOS system settings, window managers, Homebrew
- [Flake Modules](modules/flake.md) - nix settings, binary caches

## Packages

Custom packages exposed via the flake and overlays:

- [Custom Packages](packages/index.md) - `copy`, `aria2tui`, `sklauncher`, `stremio-enhanced`, etc.

## Quick Start

**Install** - see the [Installation guide](guides/installation.md) for both nixos-anywhere (remote) and ISO (physical) methods.

```bash
# Deploy to current host
just deploy

# Deploy to a remote host
just deploy obox

# Build ISO installer
just iso

# Serve docs locally
just doc
```

See [Deployment](guides/deployment.md) for full details.

## Using This Flake Externally

!!! tip "Import modules into your own flake"
    Add this repo as a flake input and import any module:

    ```nix
    {
      inputs.ndots.url = "github:semi710/ndots";

      outputs = { self, nixpkgs, ndots, ... }: {
        nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ndots.nixosModules.tailscale
            ndots.nixosModules.filebrowser
            # ... see modules docs for the full list
          ];
        };
      };
    }
    ```

    You can also fetch disko schemas and custom packages:

    ```bash
    # Fetch a partition schema
    nix eval github:semi710/ndots#disko.partition \
      --apply 'b: builtins.fromJSON (builtins.toJSON (b { device = "/dev/nvme0n1"; }))' \
      --impure

    # Run a custom package
    nix run github:semi710/ndots#copy -- "hello"
    ```
