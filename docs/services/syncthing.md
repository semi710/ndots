# Syncthing

[Syncthing](https://syncthing.net/) for peer-to-peer file sync across all devices. Managed via home-manager.

## Configuration

`modules/home/syncthing.nix`:

- Devices: mach, dsd, semi, obox
- Synced folders:
  - `~/.notes` - notes
  - `~/.dump` - general sync/dump

## Path Handling

Syncthing doesn't expand `~`. Folder paths must use absolute paths:

```nix
folders."Notes" = {
  path = "${config.home.homeDirectory}/.notes";  # NOT "~/.notes"
  devices = [ "mach" "dsd" "semi" "obox" ];
};
```

## New Folder Setup

Syncthing doesn't auto-create folders or `.stfolder` markers. For each new folder, run once per device:

```bash
mkdir -p ~/.notes
touch ~/.notes/.stfolder
```

## Certificates

Syncthing certificates and keys are stored in sops (`secrets/office.yaml`) per-device:

```yaml
syncthing:
  dsd:
    password: dsd@syncthing
    cert: |
      -----BEGIN CERTIFICATE-----
      ...
    key: |
      -----BEGIN PRIVATE KEY-----
      ...
  semi:
    password: semi@syncthing
    ...
```
