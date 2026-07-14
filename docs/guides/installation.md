# Installation

Two methods: ISO (physical access) or nixos-anywhere (remote, SSH only). Both work for any host.

## Method 1: nixos-anywhere (recommended)

For any machine reachable over SSH - servers, VMs, or physical boxes. Fully unattended: partitions, installs, reboots.

### 1. Create the host config

```bash
cp -r hosts/nixos/anywhere hosts/nixos/<name>
```

Set the platform arch in `hosts/nixos/<name>/default.nix`:

```nix
nixpkgs.hostPlatform = "x86_64-linux"; # or "aarch64-linux"
```

Adjust disk config in `hosts/nixos/<name>/disk.nix` - set the correct device path.

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

If the host uses `sops.age.keyFile` under the user home, stage that key with `--extra-files` before the first activation. `--extra-files` copies the contents of a local directory into `/` on the target, so the temp directory must mirror the target root path. Passing `~/.config/sops/age` directly would copy `keys.txt` to `/keys.txt`, not `/home/<user>/.config/sops/age/keys.txt`.

```bash
name=<name>
user=<user>
ip=<ip>

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

keydir="$tmp/home/$user/.config/sops/age"
install -d -m 700 "$keydir"
install -m 600 "$HOME/.config/sops/age/keys.txt" "$keydir/keys.txt"
```

Do not add `keys.txt` to the repo. If this is a new age key, add its public recipient to `.sops.yaml` and re-encrypt the matching secrets file first.

```bash
nix run github:nix-community/nixos-anywhere -- \
  --build-on remote \
  --option accept-flake-config true \
  --option download-buffer-size 536870912 \
  --extra-files "$tmp" \
  --chown "/home/$user/.config/sops/age" "$user:users" \
  --generate-hardware-config nixos-generate-config "./hosts/nixos/$name/hardware.nix" \
  --flake "path:$PWD#$name" \
  --target-host "root@$ip"
```

This partitions the disk, installs the system, and reboots - fully unattended. `--chown` keeps the staged age key writable by the final user so home-manager can populate `~/.config`, `--build-on remote` avoids local/target platform mismatches, `accept-flake-config` allows the flake Cachix settings during bootstrap, and the larger download buffer avoids noisy large-copy warnings.

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
