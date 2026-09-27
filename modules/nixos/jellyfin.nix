# Jellyfin bootstrap - declarative admin credentials + plugin installation for
# services.jellyfin (nixpkgs has no first-run automation and no plugin manager).
#
# Admin: sops is the source of truth for the password.
#   - first boot: admin is seeded via the startup-wizard API
#   - every boot: if the sops password no longer authenticates but the
#     previously-applied one does, the Jellyfin password is rotated to match
#   - don't change the password in the Jellyfin UI - change it in sops
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.jellyfin;

  # A .jellyfin plugin zip unpacks to meta.json + <plugin>.dll. Jellyfin loads
  # it from $configDir/plugins/<guid>/. We keep each plugin as a sourced zip
  # (fetchurl, so the hash covers the actual artifact) and unpack it into the
  # guid dir on every service start so it's hermetic and refreshable.
  pluginZips = lib.concatMapStringsSep "\n" (p: ''
    mkdir -p /var/lib/jellyfin/plugins/${p.id}
    rm -rf /var/lib/jellyfin/plugins/${p.id}/*
    ${pkgs.unzip}/bin/unzip -o -q ${p.src} -d /var/lib/jellyfin/plugins/${p.id}
  '') cfg.plugins;

  bootstrapScript = pkgs.writeShellScript "jellyfin-bootstrap" ''
    set -euo pipefail
    API=http://localhost:8096
    USER_NAME_FILE='${cfg.adminUserFile}'
    PASSWORD_FILE='${cfg.adminPasswordFile}'
    STATE_FILE="$STATE_DIRECTORY/last-password"

    USER_NAME=$(cat "$USER_NAME_FILE")
    PASSWORD=$(cat "$PASSWORD_FILE")

    for _ in $(seq 1 60); do
      curl -sf "$API/System/Info/Public" >/dev/null && break
      sleep 2
    done

    auth() {
      curl -sf -X POST "$API/Users/AuthenticateByName" \
        -H 'Content-Type: application/json' \
        -H 'X-Emby-Authorization: MediaBrowser Client="nixos-bootstrap", Device="nixos", DeviceId="nixos-bootstrap", Version="1.0.0"' \
        -d "$(jq -cn --arg u "$USER_NAME" --arg p "$1" '{Username: $u, Pw: $p}')"
    }

    OLD_PASSWORD=""
    [ -f "$STATE_FILE" ] && OLD_PASSWORD=$(cat "$STATE_FILE")

    if AUTH=$(auth "$PASSWORD"); then
      :
    elif [ -n "$OLD_PASSWORD" ] && AUTH=$(auth "$OLD_PASSWORD"); then
      # sops password rotated - update jellyfin to match
      ROTATE_TOKEN=$(jq -r '.AccessToken' <<< "$AUTH")
      USER_ID=$(jq -r '.User.Id' <<< "$AUTH")
      curl -sf -X POST "$API/Users/$USER_ID/Password" \
        -H "X-Emby-Token: $ROTATE_TOKEN" -H 'Content-Type: application/json' \
        -d "$(jq -cn --arg id "$USER_ID" --arg old "$OLD_PASSWORD" --arg new "$PASSWORD" \
              '{Id: $id, CurrentPw: $old, NewPw: $new, ResetPassword: false}')"
      echo "rotated admin password from sops"
    elif curl -sf "$API/Startup/Configuration" >/dev/null 2>&1; then
      # wizard still open - seed admin via the startup wizard API
      curl -sf -X POST "$API/Startup/User" \
        -H 'Content-Type: application/json' \
        -d "$(jq -cn --arg n "$USER_NAME" --arg p "$PASSWORD" '{Name: $n, Password: $p}')"
      curl -sf -X POST "$API/Startup/Complete"
      echo "seeded admin user"
    else
      echo "admin login failed and the setup wizard is already complete:" >&2
      echo "the sops password does not match the Jellyfin password for '$USER_NAME'." >&2
      echo "reset it in the Jellyfin UI (Profile > Password) to the sops value, or update sops." >&2
      exit 1
    fi

    printf '%s' "$PASSWORD" > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
    echo "jellyfin bootstrap: OK"
  '';
in
{
  options.services.jellyfin = {
    adminUserFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file with the admin username (e.g. a sops secret).";
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file with the admin password (e.g. a sops secret).
        Sops is the source of truth: changing the value rotates the
        Jellyfin password on the next service run.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = "Plugin guid (from its meta.json), used as the install dir name.";
            };
            src = lib.mkOption {
              type = lib.types.path;
              description = "Path to the plugin zip (use pkgs.fetchurl with the artifact hash).";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Jellyfin plugins to install declaratively. Each entry's zip is staged
        into $configDir/plugins/<id>/ on every service start.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jellyfin-bootstrap = {
      description = "Jellyfin declarative bootstrap (admin credentials + plugins)";
      after = [ "jellyfin.service" ];
      wants = [ "jellyfin.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${bootstrapScript}";
        StateDirectory = "jellyfin-bootstrap";
      };
      # stage plugins into Jellyfin's config dir before the service starts
      preStart = lib.mkIf (cfg.plugins != [ ]) ''
        ${pluginZips}
      '';
      path = [
        pkgs.curl
        pkgs.jq
      ];
    };
  };
}
