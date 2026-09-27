# Jellyfin media server browsing the gdrive media that mltb mirrors into.
# gdrive is mounted via rclone (reuses the mltb sops secret - same remote).
# Admin credentials and the library are declarative (modules/nixos/jellyfin.nix):
# sops is the source of truth for the admin password.
# Tailscale-only: port 8096, firewall stays closed.
{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  flattenScript = pkgs.writeShellScript "jellyfin-flatten" ''
    set -euo pipefail
    FLAT="$STATE_DIRECTORY"
    SRC=/mnt/gdrive/Bot

    # rebuild the flat view: clear, rescan, symlink every video into it,
    # name collisions resolve by keeping the first (task dirs contain copies)
    rm -rf "$FLAT";
    mkdir -p "$FLAT"
    find "$SRC" -type f \( -iname '*.mkv' -o -iname '*.mp4' \) -print0 |
      while IFS= read -r -d ''' f; do
        target="$FLAT/$(basename "$f")"
        [ -e "$target" ] || ln -s "$f" "$target"
      done
  '';
in
{
  imports = [
    flake.nixosModules.rclone-mount
    flake.nixosModules.jellyfin
  ];

  services.rclone-mount = {
    enable = true;
    remote = "gdrive:";
    mountpoint = "/mnt/gdrive";
    # same gdrive remote mltb uploads to - secret declared in mltb.nix
    configFilePath = config.sops.secrets."mltb/rclone.conf".path;
    cacheMaxSize = "20G";
    # streaming tuning: fast seek starts (32M chunks) + aggressive
    # read-ahead into the VFS cache so skips land on cached data
    extraArgs = [
      "--vfs-read-chunk-size"
      "32M"
      "--vfs-read-chunk-size-limit"
      "2G"
      "--vfs-read-ahead"
      "512M"
      "--buffer-size"
      "64M"
    ];
  };

  sops.secrets."jellyfin/obox/username" = { };
  sops.secrets."jellyfin/obox/password" = { };

  services.jellyfin = {
    enable = true;
    adminUserFile = config.sops.secrets."jellyfin/obox/username".path;
    adminPasswordFile = config.sops.secrets."jellyfin/obox/password".path;
    plugins = [
      {
        id = "4b9ed42f-5185-48b5-9803-6ff2989014c4"; # Open Subtitles
        src = pkgs.fetchurl {
          url = "https://repo.jellyfin.org/files/plugin/open-subtitles/open-subtitles_25.0.0.0.zip";
          sha256 = "1c0q3fjj7vkcfnscqwmzbszh6dlzhxrx6fsb5brqyyq68bp528lg";
        };
      }
      {
        id = "5c534381-91a3-43cb-907a-35aa02eb9d2c"; # Playback Reporting
        src = pkgs.fetchurl {
          url = "https://repo.jellyfin.org/files/plugin/playback-reporting/playback-reporting_19.0.0.0.zip";
          sha256 = "100ia4daiwlj8d1fjkzknbfq5xjal3g7s5ymfshp1q868kcgd6b5";
        };
      }
    ];
  };

  systemd.services.jellyfin = {
    wants = [ "rclone-mount.service" ];
    after = [ "rclone-mount.service" ];
  };

  # gdrive keeps its task-folder structure; Jellyfin gets a flat symlink
  # view of every video file under Bot/ - point the library at /var/lib/jellyfin-flat
  systemd.services.jellyfin-flatten = {
    description = "Flatten gdrive media into a symlink dir for Jellyfin";
    after = [ "rclone-mount.service" ];
    wants = [ "rclone-mount.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${flattenScript}";
      StateDirectory = "jellyfin-flat";
    };
    path = [ pkgs.findutils ];
  };

  systemd.timers.jellyfin-flatten = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";
      Persistent = true;
    };
  };
}
