{
  lib,
  stdenvNoCC,
  runtimeShell,
  mihomo,
  curl,
  writeText,
}:
let
  configTemplate = writeText "vpn-split-config.yaml" ''
    # vpn-split config - edit this file to add/remove domains, then run: vpn-split reload
    #
    # Architecture (GlobalProtect full-tunnel case):
    #   GP stays connected as the system default route. Mihomo runs as a local
    #   proxy (NOT tun). Two "direct" outbounds:
    #     direct-vpn    -> plain direct, follows default route  -> goes through GP -> office
    #     direct-bypass -> direct bound to the physical iface   -> bypasses GP    -> normal net
    #   Matched per-connection by the hostname the browser sends in CONNECT/SOCKS.
    #
    # __PHYS_IF__ is substituted at enable time with your active interface (en0/...).

    mixed-port: 7890
    allow-lan: false
    mode: rule
    log-level: info
    ipv6: false
    geo-auto-update: false

    external-controller: 127.0.0.1:9090

    dns:
      enable: true
      listen: 127.0.0.1:1053
      enhanced-mode: redir-host
      ipv6: false
      default-nameserver:
        - 1.1.1.1
        - 8.8.8.8
      nameserver:
        - "https://1.1.1.1/dns-query#direct-bypass"
      nameserver-policy:
        "+.juspay.net": system

    proxies:
      - name: direct-vpn
        type: direct
        udp: true
      - name: direct-bypass
        type: direct
        udp: true
        interface-name: __PHYS_IF__

    # ---- ROUTING RULES - edit below ------------------------------------------
    # Matched top-to-bottom. First match wins. Last line is the catch-all.
    rules:
      - DOMAIN-SUFFIX,juspay.net,direct-vpn
      - DOMAIN-SUFFIX,juspay.in,direct-vpn
      - DOMAIN-SUFFIX,juspay.aero,direct-vpn
      - DOMAIN-KEYWORD,juspay,direct-vpn
      - MATCH,direct-bypass
  '';

  script = writeText "vpn-script" ''
    #!${runtimeShell}
    set -euo pipefail

    MIHOMO="${lib.getExe mihomo}"
    CURL="${lib.getExe curl}"
    CONFIG_DIR="''${HOME}/.config/vpn-split"
    CONFIG="$CONFIG_DIR/config.yaml"
    RUNTIME_CONFIG="$CONFIG_DIR/config.runtime.yaml"
    PIDFILE="$CONFIG_DIR/mihomo.pid"
    STATEFILE="$CONFIG_DIR/state.before"
    LOGFILE="$CONFIG_DIR/mihomo.log"
    TEMPLATE="${configTemplate}"
    MIXED_PORT=7890
    CTRL="127.0.0.1:9090"

    say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
    warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
    err()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; }

    active_iface() {
      for iface in $(ifconfig -lu); do
        case "$iface" in
          lo*|utun*|gif*|stf*|pdp*|ipsec*|awdl*|llw*|anpi*|bridge*|vlan*) continue ;;
        esac
        if ifconfig "$iface" 2>/dev/null | grep -q 'inet '; then
          echo "$iface"
          return 0
        fi
      done
      return 1
    }

    is_running() {
      [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
    }

    ensure_config_dir() {
      mkdir -p "$CONFIG_DIR"
      if [[ ! -f "$CONFIG" ]]; then
        cp "$TEMPLATE" "$CONFIG"
        say "Copied default config to $CONFIG"
      fi
    }

    snapshot_state() {
      say "Snapshotting pre-state to $STATEFILE"
      {
        echo "# vpn-split pre-state snapshot $(date)"
        echo
        echo "## active interface"
        active_iface || true
        echo
        echo "## web proxy (Wi-Fi)"
        networksetup -getwebproxy "Wi-Fi" 2>/dev/null || true
        echo
        echo "## default route"
        route -n get default 2>/dev/null || true
      } > "$STATEFILE"
      echo "  saved."
    }

    set_system_proxy() {
      local iface="''${1:-Wi-Fi}"
      say "Setting system proxy on $iface (best-effort; GP may suppress)"
      sudo networksetup -setwebproxy "$iface" 127.0.0.1 "$MIXED_PORT" 2>/dev/null || true
      sudo networksetup -setsecurewebproxy "$iface" 127.0.0.1 "$MIXED_PORT" 2>/dev/null || true
      sudo networksetup -setsocksfirewallproxy "$iface" 127.0.0.1 "$MIXED_PORT" 2>/dev/null || true
      sudo networksetup -setwebproxystate "$iface" on 2>/dev/null || true
      sudo networksetup -setsecurewebproxystate "$iface" on 2>/dev/null || true
      sudo networksetup -setsocksfirewallproxystate "$iface" on 2>/dev/null || true
    }

    unset_system_proxy() {
      local iface="''${1:-Wi-Fi}"
      say "Unsetting system proxy on $iface"
      sudo networksetup -setwebproxystate "$iface" off 2>/dev/null || true
      sudo networksetup -setsecurewebproxystate "$iface" off 2>/dev/null || true
      sudo networksetup -setsocksfirewallproxystate "$iface" off 2>/dev/null || true
    }

    cmd_enable() {
      if is_running; then err "already running (pid $(cat "$PIDFILE")). use: vpn-split reload"; exit 1; fi

      ensure_config_dir

      local iface
      iface="$(active_iface)"
      if [[ -z "$iface" ]]; then
        err "could not detect physical interface"; exit 1
      fi
      if [[ "$iface" == utun* ]]; then
        err "detected interface is '$iface' (a tunnel!) - refusing."; exit 1
      fi
      say "Active physical interface: $iface"

      snapshot_state

      say "Rendering runtime config -> $RUNTIME_CONFIG"
      sed "s/__PHYS_IF__/$iface/g" "$CONFIG" > "$RUNTIME_CONFIG"

      if ! "$MIHOMO" -t -d "$CONFIG_DIR" -f "$RUNTIME_CONFIG" >/dev/null 2>"$LOGFILE"; then
        err "config validation failed:"; cat "$LOGFILE" >&2; exit 1
      fi

      say "Starting mihomo (logs: $LOGFILE)"
      nohup "$MIHOMO" -d "$CONFIG_DIR" -f "$RUNTIME_CONFIG" >>"$LOGFILE" 2>&1 &
      echo $! > "$PIDFILE"
      sleep 1
      if ! is_running; then
        err "mihomo failed to start; tail of log:"; tail -20 "$LOGFILE" >&2; exit 1
      fi
      echo "  pid $(cat "$PIDFILE")"

      set_system_proxy "Wi-Fi"

      echo
      say "ON. Work domains -> GP, everything else -> direct ($iface)."
      echo "    Edit rules in: $CONFIG  (then: vpn-split reload)"
      echo "    Zen uses PAC fallback - no restart needed."
      echo "    Reset back to baseline: vpn-split reset"
    }

    cmd_reset() {
      local had_proxy=0
      if is_running; then
        say "Stopping mihomo (pid $(cat "$PIDFILE"))"
        kill "$(cat "$PIDFILE")" 2>/dev/null || true
        rm -f "$PIDFILE"
        had_proxy=1
      else
        warn "mihomo not running"
      fi

      unset_system_proxy "Wi-Fi"
      rm -f "$RUNTIME_CONFIG"

      echo
      if (( had_proxy )); then
        say "OFF. Zen falls back to DIRECT (GP-only). No restart needed."
      else
        say "Already at baseline."
      fi
    }

    cmd_status() {
      if is_running; then
        say "mihomo: running (pid $(cat "$PIDFILE"))"
        echo "  runtime config: $RUNTIME_CONFIG"
        echo "  log: $LOGFILE"
        echo "  version: $($CURL -s http://$CTRL/version 2>/dev/null || echo '(api unreachable)')"
      else
        warn "mihomo: not running"
      fi
      echo
      echo "proxy endpoints (for manual browser config):"
      echo "  HTTP/SOCKS proxy: 127.0.0.1:$MIXED_PORT"
      echo "  PAC file:         file://$CONFIG_DIR/proxy.pac"
      echo "  control API:      http://$CTRL"
      echo
      echo "system proxy (scutil):"
      scutil --proxy 2>/dev/null | grep -E 'Enable|Proxy|Port' | sed 's/^/  /' || echo "  (unavailable)"
      echo
      echo "active iface: $(active_iface 2>/dev/null || echo '?')"
    }

    cmd_reload() {
      if ! is_running; then err "not running. use: vpn-split enable"; exit 1; fi
      local iface
      iface="$(active_iface)"
      say "Re-rendering runtime config (iface=$iface)"
      sed "s/__PHYS_IF__/$iface/g" "$CONFIG" > "$RUNTIME_CONFIG"
      if ! "$MIHOMO" -t -d "$CONFIG_DIR" -f "$RUNTIME_CONFIG" >/dev/null 2>>"$LOGFILE"; then
        err "config validation failed; NOT reloaded."; tail -10 "$LOGFILE" >&2; exit 1
      fi
      $CURL -s -X PUT "http://$CTRL/configs?force=true" \
        -H 'Content-Type: application/json' \
        -d "{\"path\":\"$RUNTIME_CONFIG\"}" >/dev/null
      say "Reloaded."
    }

    cmd_test() {
      if ! is_running; then err "not running. use: vpn-split enable"; exit 1; fi
      say "Routing decisions for sample domains:"
      local domains=("www.youtube.com" "api.juspay.net" "github.com" "in.juspay.in")
      for d in "''${domains[@]}"; do
        local code
        code="$($CURL -sS -o /dev/null -w '%{http_code}' --max-time 8 -x "http://127.0.0.1:$MIXED_PORT" "https://$d" 2>/dev/null || echo 'FAIL')"
        printf '  %-22s -> HTTP %s\n' "$d" "$code"
      done
    }

    cmd_logs() {
      tail -f "$LOGFILE"
    }

    # Print a no_proxy string derived from config.yaml rules that route to
    # direct-vpn (those domains go through GP, not mihomo - so CLI tools
    # with proxy_on should skip the proxy for them). Always includes
    # localhost and the Tailscale CGNAT range.
    cmd_no_proxy() {
      local list="localhost,127.0.0.1"
      # Extract DOMAIN-SUFFIX rules pointing to direct-vpn -> *.domain
      local domains
      domains="$(grep -E '^\s*- DOMAIN-SUFFIX,.*,direct-vpn' "$CONFIG" 2>/dev/null \
        | sed 's/.*DOMAIN-SUFFIX,\([^,]*\),.*/\1/')"
      for d in $domains; do
        list="$list,*.$d,$d"
      done
      # Tailscale CGNAT range + ts.net always bypass
      list="$list,100.64.0.0/10,*.ts.net"
      echo "$list"
    }

    case "''${1:-}" in
      enable) cmd_enable ;;
      reset|disable|stop) cmd_reset ;;
      status) cmd_status ;;
      reload) cmd_reload ;;
      test)   cmd_test ;;
      no-proxy) cmd_no_proxy ;;
      logs)   cmd_logs ;;
      *)
        cat <<HELP
    vpn-split - route work domains via GlobalProtect, rest direct.

    Commands:
      enable            start mihomo, set system proxy (best-effort)
      reset | disable | stop   stop mihomo, unset system proxy
      status            show running state + proxy endpoints + settings
      reload            re-read config.yaml without restart (after editing rules)
      test              test routing decisions for sample domains
      logs              tail the mihomo log

    Edit rules in: $CONFIG
    Zen proxy is managed declaratively via PAC (Home Manager).
    HELP
        exit 1 ;;
    esac
  '';
in
stdenvNoCC.mkDerivation {
  pname = "vpn-split";
  version = "0.1.0";

  nativeBuildInputs = [ ];

  unpackPhase = "true";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/vpn-split

    cp ${script} $out/bin/vpn-split
    chmod +x $out/bin/vpn-split
    patchShebangs $out/bin/vpn-split

    cp ${configTemplate} $out/share/vpn-split/config.yaml

    runHook postInstall
  '';

  meta = {
    description = "Split-tunnel proxy: route work domains via GP, rest direct";
    mainProgram = "vpn-split";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
