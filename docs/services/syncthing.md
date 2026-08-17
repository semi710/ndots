# Syncthing

[Syncthing](https://syncthing.net/) for peer-to-peer file sync across all devices. Managed via home-manager.

## Configuration

`modules/home/syncthing.nix`:

- Devices: semi, mach, jp-mbp, dsd
- Synced folders:
  - `~/.notes` - notes (Obsidian vault)
  - `~/.dump` - general sync/dump

## Path Handling

Syncthing doesn't expand `~`. Folder paths must use absolute paths:

```nix
folders."${config.home.homeDirectory}/.notes" = rec {
  id = "notes";
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

## Adding a New Device

See [Adding a New Host - Syncthing](../guides/new-host.md#4-syncthing) for the full checklist. Summary:

1. Generate device ID + cert/key: `nix run nixpkgs#syncthing -- generate --home=/tmp/syncthing-gen`
2. Store cert/key/password in the appropriate sops file
3. Add device to `allDevices` + `settings.devices` in `modules/home/syncthing.nix`
4. Import `flake.homeModules.syncthing` + wire sops secrets in the host's user config
5. Create folders after first deploy: `mkdir -p ~/.notes ~/.dump && touch ~/.notes/.stfolder ~/.dump/.stfolder`

## .stignore

The notes folder ignores `.obsidian/` (device-specific workspace layout, app settings). Because Syncthing 2.1.x opens `.stignore` with `O_NOFOLLOW` (rejecting symlinks), and home-manager creates nix-store symlinks, the `.stignore` file is written as a regular file via a home activation script:

```nix
home.activation.stignoreNotes = lib.hm.dag.entryAfter [ "writeBoundary" "icloudNotesLink" ] ''
  if [ -L "$HOME/.notes/.stignore" ]; then
    run rm -f "$HOME/.notes/.stignore"
  fi
  run sh -c 'mkdir -p "$HOME/.notes" && printf "/.obsidian\n" > "$HOME/.notes/.stignore"'
  run chmod 644 "$HOME/.notes/.stignore"
'';
```
