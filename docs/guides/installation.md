# Installation

Two methods: ISO (physical access) or nixos-anywhere (remote, SSH only). Both work for any host.

## Method 1: nixos-anywhere (recommended)

For any machine reachable over SSH — servers, VMs, or physical boxes. Fully unattended: partitions, installs, reboots.

### 1. Create the host config

```bash
cp -r hosts/nixos/anywhere hosts/nixos/<name>
```

Set the platform arch in `hosts/nixos/<name>/default.nix`:

```nix
nixpkgs.hostPlatform = "x86_64-linux"; # or "aarch64-linux"
```

Adjust disk config in `hosts/nixos/<name>/disk.nix` — set the correct device path.

### 2. Add services and secrets

Import the modules you need:

```nix
imports = [
  flake.nixosModules.beszel
  flake.nixosModules.tailscale
  flake.nixosModules.virtualisation
  flake.nixosModules.filebrowser
  flake.inputs.sops-nix.nixosModules.sops
];
```

Wire secrets:

```nix
sops.secrets."tailscale_auth_key" = { };
services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
```

### 3. Install

```bash
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hosts/nixos/<name>/hardware.nix \
  --flake .#<name> \
  --target-host root@<ip>
```

This partitions the disk, installs the system, and reboots — fully unattended.

### 4. Deploy future updates

```bash
just deploy <name>
```

## Method 2: ISO install (physical access)

### 1. Boot the ISO

Boot from the [pre-built ISO](iso.md) or upstream NixOS minimal ISO.

### 2. Connect to the internet

```bash
nmtui  # WiFi via NetworkManager
```

### 3. Partition the disk

```bash
nix eval github:semi710/ndots#disko.partition \
  --apply 'b: builtins.fromJSON (builtins.toJSON (b { device = "/dev/nvme0n1"; ssdOptions = []; }))' \
  --impure > disko-config.nix

sudo disko --mode destroy,format,mount --yes-wipe-all-disks ./disko-config.nix
```

### 4. Install

```bash
sudo nixos-install --no-root-passwd --root /mnt --flake github:semi710/ndots#<hostname>
```

!!! note "Root password"
    Omit `--no-root-passwd` if you want to set a root password during install. After setting your user password, lock root:
    ```bash
    sudo passwd -l root
    ```

### 5. Reboot and deploy

```bash
reboot
# After reboot, SSH in and deploy:
just deploy
```

## After Installing

- Add the host to `config.nix` if it's a nix remote builder
- Add SSH known hosts if it needs to cross-build with other hosts
- Add to the docs: `docs/hosts/<name>.md`, update `mkdocs.yml` nav
