# MLTB (mirror-leech-telegram-bot)

[mirror-leech-telegram-bot](https://github.com/semi710/mirror-leech-telegram-bot) (fork of [anasty17/mltb](https://github.com/anasty17/mirror-leech-telegram-bot)) - mirrors/leeches files from the internet to Telegram or any rclone remote. Runs on **obox** only.

## Configuration

- Packaged as a flake (`github:semi710/mirror-leech-telegram-bot`) - Python env built from `uv.lock` via uv2nix, bot source shipped in the package
- Runs as **root** by design: the bot's daemon startup chain hardcodes `/root/.netrc`; non-root silently breaks aria2/qbittorrent/sabnzbd downloads
- `/app` is a tmpfiles symlink to the data dir (docker heritage - `DOWNLOAD_DIR` is hardcoded to `/app/downloads/`)
- `config.py` and `rclone.conf` are re-installed from sops on every service start; runtime edits via bot commands persist in the bot's database and are overwritten on restart
- Daemon helpers (aria2c, qbittorrent-nox, sabnzbd) are started by the bot itself via `aria-nox-nzb.sh` and stay in the service cgroup - systemd reaps them on stop
- Uploads go to `gdrive:Bot` via rclone

## Module

`hosts/nixos/obox/mltb.nix` imports `mltb.nixosModules.mltb` from the flake input:

```nix
services.mltb = {
  enable = true;
  configFile = config.sops.secrets."mltb/config.py".path;
  rcloneConfigFile = config.sops.secrets."mltb/rclone.conf".path;
};
```

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | - | Enable the service |
| `package` | flake package | The mltb derivation |
| `dataDir` | `/var/lib/mltb` | Mutable state: config, downloads, daemon profiles |
| `user`/`group` | `root` | Service user (see note above) |
| `configFile` | - | Path to a `config.py`, installed into `dataDir` each start |
| `rcloneConfigFile` | `null` | Optional `rclone.conf`, installed into `dataDir` each start |
| `environment` | `{}` | Extra env vars |

## Secrets

Stored in `secrets/server.yaml` (mltb group):

- `mltb.config.py` - full bot config (BOT_TOKEN, TELEGRAM_API/HASH, etc.)
- `mltb.rclone.conf` - gdrive remote with OAuth tokens

Update with: `sops edit secrets/server.yaml`

## State

Everything mutable lives in `/var/lib/mltb`:

- `downloads/` - in-flight downloads
- `sabnzbd/`, `qBittorrent/` - daemon profiles (seeded from the package, never overwritten)
- `token.pickle`, `accounts/`, `.netrc` - optional private files, managed manually if needed

## Troubleshooting

```bash
sudo systemctl status mltb
sudo journalctl -u mltb -f
```

After changing sops secrets: `sudo systemctl restart mltb` (config is only read at start).
