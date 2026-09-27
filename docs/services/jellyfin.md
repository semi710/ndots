# Jellyfin

[Jellyfin](https://jellyfin.org) - media server with a full library UI (posters, metadata, watch progress). Runs on **obox**, serving the gdrive media that [MLTB](mltb.md) mirrors in.

## Configuration

- **Public** at `https://jellyfin.semi.sh` via Caddy (route in `/etc/caddy/Caddyfile` on obox); port 8096 itself stays closed
- gdrive mounted at `/mnt/gdrive` via the `rclone-mount` module (FUSE, VFS cache capped at 20G in `/var/cache/rclone-mount`, streaming-tuned chunk/read-ahead flags)
- Reuses the mltb sops secret `mltb/rclone.conf` - same gdrive remote the bot uploads to
- New files appear automatically: rclone polls gdrive for changes (~1 min)
- Software transcoding only (Neoverse-N1 has no GPU) - 1080p is fine, 4K transcodes will struggle; prefer direct play clients
- **Flat media view:** the `jellyfin-flatten` timer (every 10 min) mirrors every video under `/mnt/gdrive/Bot` as symlinks into `/var/lib/jellyfin-flat`, so Jellyfin can use a flat library instead of browsing the task-folder tree. Point the library at `/var/lib/jellyfin-flat` for a clean poster wall while gdrive keeps its structure.

## Playback on this CPU

obox has **no GPU** (Ampere Neoverse-N1), so all hardware-accelerated transcoding is unavailable:
- **Hardware decoding / AV1 encode / HW MJPEG** - no-op on this chip; leave off
- **HEVC encoding** - works but as *software* encode; enabling it in the UI (Dashboard -> Playback -> allowed transcoding) makes forced burns H.265->H.265 instead of H.265->H.264, roughly halving CPU load
- **Tone mapping** (HDR) - pure software here, expensive; leave off unless you need it
- **Bitrate limit** (Dashboard -> Streaming): set to ~80-85 Mbps if your viewer link is ~100M, to stop stubborn clients requesting more than your pipe

The real fix for slowness on this box is **direct play** - use a client with hardware decode (Jellyfin Desktop/Infuse/Kodi, or Chrome/Chromium with VA-API). Firefox cannot decode HEVC at all and forces software transcoding; keep it for admin, not viewing.

Skipping hits a wall specifically when **transcoding**: every mid-file skip restarts a CPU re-encode (H.265->H.264 on 4 ARM cores), which reads as a long freeze. The rclone mount is tuned for the fastest possible gdrive seeks (32M chunks growing to 2G, 512M read-ahead) - those are already optimal. The remaining gap is the transcode reload, so a direct-play client makes seeks effectively instant. The H.264 files in the library direct-play even in a browser; the H.265 ones do not.

## First Setup

Admin credentials are declarative - no wizard typing on a fresh install:

1. Add credentials to sops (`secrets/server.yaml`):

```yaml
jellyfin:
    obox:
        username: semi
        password: <password>
```

2. Deploy. The `jellyfin-bootstrap` oneshot seeds the admin user via the startup-wizard API.
3. Log in and add the media library once via the UI (Dashboard -> Libraries) - e.g. `/mnt/gdrive/Bot`. Library layout is Jellyfin-owned state, intentionally not managed by the module.

**Password rotation:** sops is the source of truth. Change `jellyfin.<host>.password` in sops and redeploy/restart - the bootstrap notices the old password still authenticates, and rotates Jellyfin to the new one. Don't change the password in the Jellyfin UI; if you did, change it back (or update sops to match) or the bootstrap unit will fail with a clear log.

**New server:** add a `jellyfin.<host>.username` + `jellyfin.<host>.password` sops entry, copy the host file, adjust the mount/library paths.

## Modules

`modules/nixos/rclone-mount.nix` (exposed as `flake.nixosModules.rclone-mount`):

```nix
services.rclone-mount = {
  enable = true;
  remote = "gdrive:";
  mountpoint = "/mnt/gdrive";
  configFilePath = config.sops.secrets."mltb/rclone.conf".path;
  cacheMaxSize = "20G";
  extraArgs = [ ];  # e.g. [ "--dir-cache-time" "1h" ]
};
```

`modules/nixos/jellyfin.nix` (exposed as `flake.nixosModules.jellyfin`) adds declarative credentials + plugins to nixpkgs' `services.jellyfin`:

```nix
services.jellyfin = {
  enable = true;
  adminUserFile = config.sops.secrets."jellyfin/<host>/username".path;
  adminPasswordFile = config.sops.secrets."jellyfin/<host>/password".path;
  plugins = [
    {
      id = "4b9ed42f-5185-48b5-9803-6ff2989014c4"; # Open Subtitles
      src = pkgs.fetchurl {
        url = "https://repo.jellyfin.org/files/plugin/open-subtitles/open-subtitles_25.0.0.0.zip";
        sha256 = "1c0q3fjj7vkcfnscqwmzbszh6dlzhxrx6fsb5brqyyq68bp528lg";
      };
    }
  ];
};
```

Plugins are fetched (hashed zip) and unzipped into `/var/lib/jellyfin/plugins/<guid>/` on every service start. Get the version/artifact and guid from the [Jellyfin plugin repo](https://repo.jellyfin.org/files/plugin/). `sha256` can be obtained with `nix-prefetch-url <zip-url>`. InfuseSync (and other pre-10.8 plugins) no longer load on modern Jellyfin - install only current-ABI plugins.

## Troubleshooting

```bash
systemctl status rclone-mount jellyfin
journalctl -u rclone-mount -f        # mount errors, drive API rate limits
ls /mnt/gdrive                       # mount sanity check
```

If the mount fails after a token revoke: `sops edit secrets/server.yaml` (the OAuth token lives in `mltb.rclone.conf`), then `systemctl restart rclone-mount mltb`.
