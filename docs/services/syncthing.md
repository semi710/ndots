# Syncthing

[Syncthing](https://syncthing.net/) for peer-to-peer file sync across all devices. Managed via home-manager.

## Configuration

`modules/home/syncthing.nix`:

- Devices: semi, mach, jp-mbp, dsd, obox
- Synced folders are defined per-user in the shared module

## Path Handling

Syncthing doesn't expand `~`. Folder paths must use absolute paths:

```nix
folders."${config.home.homeDirectory}/<folder>" = rec {
  id = "<folder>";
  name = id;
  devices = allDevices;
};
```

## New Folder Setup

Syncthing auto-creates the folder directory and `.stfolder` marker when it accepts the folder config from home-manager. No manual setup needed.

## Certificates

Syncthing TLS certificates and GUI passwords are stored in sops per-device. The sops file depends on which age key the host uses:

| Host | Sops file | Sops key prefix |
|------|-----------|-----------------|
| semi, dsd | `secrets/office.yaml` | `syncthing/<host>/` |
| obox, mach | `secrets/server.yaml` | `syncthing/<host>/` |
| jp-mbp | `secrets/keys.yaml` | `syncthing/<host>/` |

## Adding a New Device

Each device needs a **device ID** (public identifier, derived from the TLS cert), a **TLS cert + key** (stored in sops for consistent identity across rebuilds), and a **GUI password** (stored in sops).

### 1. Generate Identity

On the new host:

```bash
nix run nixpkgs#syncthing -- generate --home=/tmp/syncthing-gen
```

This prints the device ID and creates:

| File | Sops key |
|------|----------|
| `/tmp/syncthing-gen/cert.pem` | `syncthing/<host>/cert` |
| `/tmp/syncthing-gen/key.pem` | `syncthing/<host>/key` |

### 2. Add to Sops

Add the cert, key, and a GUI password to the appropriate sops file (see table above):

```yaml
syncthing:
  <host>:
    password: <chosen-password>
    cert: |
      -----BEGIN CERTIFICATE-----
      ...
    key: |
      -----BEGIN EC PRIVATE KEY-----
      ...
```

Clean up: `rm -rf /tmp/syncthing-gen`

### 3. Register in Shared Module

Edit `modules/home/syncthing.nix`:

1. Add hostname to `allDevices` list
2. Add device entry with the device ID from step 1:

```nix
allDevices = [ "semi" "mach" "jp-mbp" "dsd" "<host>" ];

settings.devices."<host>" = {
  name = "<host>";
  id = "<DEVICE-ID-FROM-STEP-1>";
  autoAcceptFolders = true;
};
```

### 4. Wire in User Config

In `hosts/nixos/<host>/users/<user>.nix`:

```nix
imports = [
  flake.homeModules.sops
  flake.homeModules.syncthing
];

sops.secrets = {
  "syncthing/<host>/password" = {
    sopsFile = "${flake}/secrets/server.yaml";  # or office.yaml/keys.yaml
  };
  "syncthing/<host>/cert" = {
    sopsFile = "${flake}/secrets/server.yaml";
  };
  "syncthing/<host>/key" = {
    sopsFile = "${flake}/secrets/server.yaml";
  };
};

services.syncthing = {
  guiCredentials = {
    username = host.username;
    passwordFile = config.sops.secrets."syncthing/<host>/password".path;
  };
  cert = config.sops.secrets."syncthing/<host>/cert".path;
  key = config.sops.secrets."syncthing/<host>/key".path;
};
```

### 5. Deploy and Verify

After deploy, syncthing auto-creates the folders and `.stfolder` markers. Verify:

```bash
systemctl --user status syncthing
```

!!! note "First boot race"
    On first boot, `syncthing-init.service` may fail with a dependency error if syncthing hasn't started yet. Run `systemctl --user start syncthing-init` manually to push the config.

## .stignore

Folders can ignore specific paths (e.g., device-specific app settings). Because Syncthing 2.1.x opens `.stignore` with `O_NOFOLLOW` (rejecting symlinks), and home-manager creates nix-store symlinks, the `.stignore` file is written as a regular file via a home activation script:

```nix
home.activation.stignoreNotes = lib.hm.dag.entryAfter [ "writeBoundary" "icloudNotesLink" ] ''
  if [ -L "$HOME/<folder>/.stignore" ]; then
    run rm -f "$HOME/<folder>/.stignore"
  fi
  run sh -c 'mkdir -p "$HOME/<folder>" && printf "/<ignore-pattern>\n" > "$HOME/<folder>/.stignore"'
  run chmod 644 "$HOME/<folder>/.stignore"
'';
```
