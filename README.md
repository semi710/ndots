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
<br><br>
<h3>📚 <a href="https://ndots.semi.sh">ndots.semi.sh</a> — Full Documentation</h3>
<br>
<sub>Architecture · Modules · Hosts · Services · Guides · Secrets · Packages · ISO</sub><br>

![GitHub repo size](https://img.shields.io/github/repo-size/semi710/ndots)
![GitHub Org's stars](https://img.shields.io/github/stars/semi710%2Fndots)
![GitHub forks](https://img.shields.io/github/forks/semi710/ndots)
![GitHub last commit](https://img.shields.io/github/last-commit/semi710/ndots)

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

## Hosts

| Host | Platform | Arch | CPU | RAM | Role |
|------|----------|------|-----|-----|------|
| **mach** | NixOS | x86_64 | Intel i7-10510U (4c/8t) | 24 GB | Personal laptop |
| **dsd** | NixOS | x86_64 | Intel i9-12900KS (16c/24t) | 64 GB | Work desktop |
| **semi** | NixOS | x86_64 | Intel i9-14900K (24c/32t) | 128 GB | Semi-personal |
| **obox** | NixOS | aarch64 | Ampere Neoverse-N1 (4c/4t) | 24 GB | Oracle Cloud VPS |
| **jp-mbp** | Darwin | aarch64 | Apple M4 | — | MacBook Pro |

---

## Quick Start

```bash
# Install (from ISO or minimal ISO)
nix eval github:semi710/ndots#disko.partition \
  --apply 'b: builtins.fromJSON (builtins.toJSON (b { device = "/dev/nvme0n1"; ssdOptions = []; }))' \
  --impure > disko-config.nix
sudo disko --mode destroy,format,mount --yes-wipe-all-disks ./disko-config.nix
sudo nixos-install --no-root-passwd --root /mnt --flake github:semi710/ndots#<hostname>
```

```bash
# Deploy
just deploy              # Current host
just deploy obox         # Remote host
just iso                 # Build installer ISO
```

---

## Related

- **[Utils](https://github.com/semi710/utils)** — Utility scripts (Hyprland, Yabai, Rofi)
- **[nvix](https://github.com/semi710/nvix)** — Neovim configuration
- **[nix-wire](https://github.com/semi710/nix-wire)** — Flake auto-wiring library
- **[OG Branch](https://github.com/semi710/ndots/tree/OG)** — Full ricing with Hyprland/Wayland

### Acknowledgments

Thanks to all the amazing NixOS community members whose configurations inspired this setup:
[iynaix](https://github.com/iynaix), [fufexan](https://github.com/fufexan), [nobbZ](https://github.com/nobbZ), [lilleaila](https://github.com/lilleaila), [vimjoyer](https://github.com/vimjoyer), [srid](https://github.com/srid)
