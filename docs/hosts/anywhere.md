# anywhere - Generic Host Template

A bare NixOS server template for bootstrapping new machines via [nixos-anywhere](https://github.com/nix-community/nixos-anywhere). No services, no sops, no home-manager - just enough to boot and SSH in.

## Usage

1. **Copy the template:**
   ```bash
   cp -r hosts/nixos/anywhere hosts/nixos/<name>
   ```

2. **Set the platform arch** in `hosts/nixos/<name>/default.nix`:
   ```nix
   nixpkgs.hostPlatform = "x86_64-linux"; # or "aarch64-linux"
   ```

3. **Adjust disk config** in `hosts/nixos/<name>/disk.nix` - set the correct device path.

4. **Install via nixos-anywhere:**
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --generate-hardware-config nixos-generate-config ./hosts/nixos/<name>/hardware.nix \
     --flake .#<name> \
     --target-host root@<ip>
   ```

   This partitions the disk, installs the system, and reboots - fully unattended.

5. **Deploy future updates:**
   ```bash
   just deploy <name>
   ```

## What's Included

- GRUB with EFI
- NetworkManager
- OpenSSH
- `virt` user (from `config.nix`) with SSH keys
- zsh shell
- Nix settings (latest nix, GC, caches)

## What to Add

For production hosts, import the relevant modules:

```nix
imports = [
  flake.nixosModules.beszel
  flake.nixosModules.tailscale
  flake.nixosModules.virtualisation
  flake.nixosModules.filebrowser
  flake.inputs.sops-nix.nixosModules.sops
  # ... add home-manager, user config, etc.
];
```
