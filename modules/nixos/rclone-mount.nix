# rclone mount as a systemd service - FUSE mount of a single rclone remote.
# The config comes from a sops-rendered rclone.conf passed via configFilePath.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rclone-mount;
in
{
  options.services.rclone-mount = {
    enable = lib.mkEnableOption "rclone mount";

    remote = lib.mkOption {
      type = lib.types.str;
      example = "gdrive:";
      description = "Remote:path to mount.";
    };

    mountpoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/rclone";
      description = "Where to mount the remote.";
    };

    configFilePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to an rclone.conf (e.g. a sops secret). Read-only is fine.";
    };

    cacheMaxSize = lib.mkOption {
      type = lib.types.str;
      default = "10G";
      description = "VFS cache size cap (--vfs-cache-max-size).";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra rclone mount flags, e.g. [ \"--dir-cache-time\" \"1h\" ].";
    };
  };

  config = lib.mkIf cfg.enable {
    # --allow-other so non-root services (e.g. jellyfin) can read the mount
    programs.fuse.userAllowOther = lib.mkDefault true;

    systemd.services.rclone-mount = {
      description = "rclone mount (${cfg.remote} at ${cfg.mountpoint})";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      preStart = ''
        # clear a stale mount left by a killed rclone (e.g. the unit restarted
        # while something held file handles open) - systemd guarantees the
        # previous process is dead before we run, so any mount here is orphaned
        ${pkgs.fuse3}/bin/fusermount3 -uz ${cfg.mountpoint} 2>/dev/null || true
        mkdir -p ${cfg.mountpoint}
      '';

      serviceConfig = {
        # rclone in the foreground; the kernel cleans up the mount on exit
        ExecStart = lib.concatStringsSep " " (
          [
            (lib.getExe pkgs.rclone)
            "mount"
            cfg.remote
            cfg.mountpoint
            "--config"
            cfg.configFilePath
            "--allow-other"
            "--vfs-cache-mode"
            "full"
            "--vfs-cache-max-size"
            cfg.cacheMaxSize
            "--cache-dir"
            "%C/rclone-mount"
          ]
          ++ cfg.extraArgs
        );
        CacheDirectory = "rclone-mount";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
