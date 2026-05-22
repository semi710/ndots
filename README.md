> [!NOTE]
> **Welcome!**
>
> This is a simplified branch of my Nix configuration. For complete documentation, setup details, ricing, and advanced configurations (impermanence, disko, secure boot), check out the **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)**.

<p align="center" style="color:grey">

![image](https://github.com/user-attachments/assets/1f1600e9-a1d9-4aa6-9035-5d19e4ece908)

<div align="center">

<small><small>**[gdots](https://github.com/niksingh710/gdots) + [cdots](https://github.com/niksingh710/cdots)**</small>

</div>

<div align="center">
<table>
<tbody>
<td align="center">
<img width="2000" height="0"><br>

My **[NixOS](https://nixos.org)/[Nix Config](https://nixos.org/download/#download-nix)** built using flakes.<br>
I've used **[Flake-Parts](https://flake.parts)** to modularize the config.<br>
<small>**Hyprland + Waybar Setup**</small><br>
<small>**Yabai/Aerospace on Darwin**</small><br>

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

## Quick Install

### Prerequisites
1. **Connect to the internet**
   - The ISO includes NetworkManager, so you can use `nmtui` to connect to WiFi

2. **Get the disko configuration**
   ```bash
   # Replace <hostname> with your target hostname (e.g., mach, vm, jp-mbp)
   nix eval github:niksingh710/ndots#disko.partition \
     --apply 'b: builtins.fromJSON (builtins.toJSON (b { device = "/dev/nvme0n1"; ssdOptions = []; }))' \
     --impure > disko-config.nix
   ```

3. **Partition the disk**
   ```bash
   sudo disko --mode destroy,format,mount --yes-wipe-all-disks ./disko-config.nix
   ```

4. **Install the system**
   ```bash
   sudo nixos-install --no-root-passwd --root /mnt --flake github:niksingh710/ndots#<hostname>
   ```

> For general instructions, troubleshooting, and detailed setup information, see the **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)**.

---

## 📋 Hosts

| Host      | Description |
| --------- | ----------- |
| **mach**  | Personal laptop (CLI only) |
| **dsd**   | Work desktop (CLI only) |
| **semi**  | Semi-personal machine (CLI only) |
| **virt**  | Virtual Machine testing (CLI only) |
| **iso**   | Custom installer ISO with NetworkManager, home-manager, and pre-configured setup |
| **jp-mbp** | MacBook Pro M4 (Darwin) |

---

## Preview

<details>
  <summary>🖥️ Current Setup Previews</summary>

### Linux (CLI Mode)

My current setup is **fully CLI-based**, accessed via **Tailscale**.

![Shell Preview](https://github.com/user-attachments/assets/9d5d8491-1b3e-4e78-9d0d-6c8920560c82)

![FZF Preview](https://github.com/niksingh710/cdots/assets/60490474/6a96631d-02c0-4c5a-a777-1edaff594081)


|![image](https://github.com/user-attachments/assets/1cd4da7d-ef2c-45f8-9a14-ada0288e1d6d) |![Image](https://github.com/user-attachments/assets/a8403f60-b58f-47ff-be3a-f51ed8e28306) |
|-|-|

| ![discord](https://github.com/user-attachments/assets/6921057d-1c40-417f-a652-a0063e98a55b) | ![telegram](https://github.com/user-attachments/assets/22afed68-5ce7-4d1e-8866-3ad46f613a85) |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |

![image](https://github.com/user-attachments/assets/ee3824ed-5d00-4f77-9661-fe2c3d4fcf32)

![image](https://github.com/user-attachments/assets/151cc1af-7841-497b-8d43-516f78c24048)

You can find more UI previews in my old repository: [gdots](https://github.com/niksingh710/gdots) or in my [Hacky issue](https://github.com/niksingh710/ndots/issues/1)

**Colors are adapted from the wallpapers**

- For Telegram I have ported `walogram` theme generator for my stylix config.

I’ve used **[Stylix](https://github.com/danth/stylix)** for theming.

Check out my favorite color schemes on [base16](https://github.com/niksingh710/base-16-colors).

### Darwin (Yabai)

On Darwin systems (MacBook), I use **Yabai** for window management.

</details>

## 📦 Build ISO

```bash
nix build .#iso.iso
```

The ISO will be available in `result/iso/`. The ISO includes home-manager for the `nixos` user with shell, editor, ssh, and nix-index configured.

## 🛠️ Flake Parts

This configuration uses **[Flake-Parts](https://flake.parts)** to modularize the setup. Check the `parts/` directory for:
- `disko/` - Disk partitioning configurations
- `iso/` - ISO build alias (wired via [nix-wire](https://github.com/semi710/nix-wire))

Built with **[nix-wire](https://github.com/semi710/nix-wire)** — auto-wiring for hosts, modules, overlays, and templates.

## 🔗 Related

- **[Utils](https://github.com/niksingh710/utils)** - Utility scripts and tools
- **[OG Branch](https://github.com/niksingh710/ndots/tree/OG)** - Full documentation and ricing

### Acknowledgments

Thanks to all the amazing NixOS community members whose configurations inspired this setup:
[iynaix](https://github.com/iynaix), [fufexan](https://github.com/fufexan), [nobbZ](https://github.com/nobbZ), [lilleaila](https://github.com/lilleaila), [vimjoyer](https://github.com/vimjoyer), [srid](https://github.com/srid)
