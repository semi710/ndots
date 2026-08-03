{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.ndots.hyprland.monitor;
in
{
  options.ndots.hyprland.monitor = {
    primary = lib.mkOption {
      type = lib.types.str;
      default = "DP-3";
      description = ''
        Primary monitor string
      '';
    };
    secondary = lib.mkOption {
      type = lib.types.str;
      default = "DP-4";
      description = ''
        Secondary monitor string
      '';
    };
  };

  config = {
    wayland.windowManager.hyprland.settings = {
      xwayland.force_zero_scaling = true;
      monitor = [
        "eDP-1,disable"
        "${cfg.primary},preferred,auto-right,1,bitdepth,10"
        "${cfg.secondary},preferred,auto-right,1,bitdepth,10,transform,3"
      ];

      workspace = [
        "1,monitor:${cfg.primary},default:true"
        "2,monitor:${cfg.primary},default:true"
        "3,monitor:${cfg.primary},default:true"
        "4,monitor:${cfg.primary},default:true"
        "5,monitor:${cfg.primary},default:true"
        "6,monitor:${cfg.primary},default:true"
        "7,monitor:${cfg.primary},default:true"
        "8,monitor:${cfg.primary},default:true"
        "9,monitor:${cfg.primary},default:true"
        "10,monitor:${cfg.secondary},default:true"
      ];
      exec = [
        "sleep 5s && uwsm -- app ${lib.getExe (
          pkgs.writeShellScriptBin "ipc" ''
            set -o pipefail
            export PATH="${
              lib.makeBinPath (
                with pkgs;
                [
                  libnotify
                  socat
                  jq
                ]
              )
            }:$PATH"
            handle() {
              if [[ ''${1:0:14} == "monitorremoved" ]]; then
                notify "Monitor removed"
                "${lib.getExe pkgs.putils.monitor}"
              fi

              if [[ ''${1:0:14} == "monitoraddedv2" ]]; then
                notify "Monitor added"
                "${lib.getExe pkgs.putils.monitor}"
              fi
            }

            socat - \
            UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
            while read -r line; do handle "$line"; done
          ''
        )}"
      ];
    };
  };
}
