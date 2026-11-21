{ lib, pkgs, ... }:
{
  programs.zsh.initContent = lib.mkOrder 1600 ''
    ts-status() {
      tailscale status --json |
        ${lib.getExe pkgs.jq} -r '
          .Peer[] |
          [
            (if .Online then "ONLINE" else "OFFLINE" end),
            .HostName,
            (
              if .OS == "linux" then ""
              elif .OS == "macOS" then ""
              elif .OS == "windows" then ""
              elif .OS == "android" then ""
              elif .OS == "iOS" then ""
              else "?"
              end
            ),
            .OS,
            (.TailscaleIPs[0] // "-")
          ] | @tsv
        ' |
        while IFS=$'\t' read -r state hostname icon os ip; do
          if [[ "$state" == "ONLINE" ]]; then
            printf '│ \033[1;32m● Online\033[0m   │ %-23s │ %-14s │ %-15s │\n' \
              "$hostname" "$icon $os" "$ip"
          else
            printf '│ \033[90m●\033[0m Offline  │ %-23s │ %-14s │ %-15s │\n' \
              "$hostname" "$icon $os" "$ip"
          fi
        done |
        {
          printf '┌────────────┬─────────────────────────┬────────────────┬─────────────────┐\n'
          printf '│ STATUS     │ HOSTNAME                │ OS             │ IP              │\n'
          printf '├────────────┼─────────────────────────┼────────────────┼─────────────────┤\n'
          cat
          printf '└────────────┴─────────────────────────┴────────────────┴─────────────────┘\n'
        }
    }
  '';
}
