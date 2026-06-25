# FileBrowser Quantum — systemd service wrapping the nixpkgs binary.
# Admin user auto-derived from hostname. Password comes from sops via passwordFile.
# Runs as root for full filesystem access (Tailscale-only, not exposed publicly).
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.filebrowser-quantum;
  host = config.networking.hostName;
  dataDir = "/var/lib/filebrowser-quantum";
  sources = lib.unique (cfg.sources ++ [ cfg.home ]);
  configFile = pkgs.writeText "filebrowser-quantum.yaml" (
    builtins.toJSON {
      server = {
        port = cfg.port;
        baseURL = "/";
        database = "${dataDir}/database.db";
        disableUpdateCheck = true;
        sources = map (path: { inherit path; }) sources;
      };
      auth = {
        adminUsername = host;
        adminPassword = "";
        methods.password = {
          enabled = true;
          minLength = 5;
          signup = false;
        };
      };
    }
  );
in
{
  options.services.filebrowser-quantum = {
    enable = lib.mkEnableOption "FileBrowser Quantum";

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/" ];
      description = "Source directories to serve (home is added automatically)";
    };

    home = lib.mkOption {
      type = lib.types.str;
      description = "User home directory to add as a source";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4321;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to sops secret file containing the admin password";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.filebrowser-quantum = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = cfg.user;
        StateDirectory = "filebrowser-quantum";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'PASS=$(cat ${cfg.passwordFile}) && ${pkgs.filebrowser-quantum}/bin/filebrowser-quantum set -u ${host},$PASS -a -c ${configFile}'";
        ExecStart = "${pkgs.filebrowser-quantum}/bin/filebrowser-quantum -c ${configFile}";
        Restart = "on-failure";
      };
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
