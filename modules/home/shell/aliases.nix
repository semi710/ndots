{ pkgs, lib, ... }:
let
  nxbuild = pkgs.writeShellScriptBin "nxbuild" ''
    # nxbuild - Build nix packages on remote builders
    # If a host is given, uses --builders (ad-hoc). Otherwise uses nix.buildMachines.
    set -euo pipefail

    # Colors (disabled if not a terminal)
    if [[ -t 1 ]]; then
      BOLD='\033[1m'
      DIM='\033[2m'
      GREEN='\033[32m'
      BLUE='\033[34m'
      YELLOW='\033[33m'
      CYAN='\033[36m'
      RESET='\033[0m'
    else
      BOLD="" DIM="" GREEN="" BLUE="" YELLOW="" CYAN="" RESET=""
    fi

    show_help() {
      echo -e "''${BOLD}''${CYAN}nxbuild''${RESET} - Build nix packages on remote builders"
      echo ""
      echo -e "''${BOLD}Usage:''${RESET}"
      echo -e "  nxbuild ''${YELLOW}[host]''${RESET} [options...] [nix build args...]"
      echo -e "  nxbuild [options...] [nix build args...]       (uses configured builders)"
      echo ""
      echo -e "''${BOLD}Options:''${RESET}"
      echo -e "  ''${GREEN}-s, --system''${RESET} SYS       Target system (default: current system)"
      echo -e "  ''${GREEN}-j, --max-jobs''${RESET} N       Max parallel builds on remote (default: 8)"
      echo -e "  ''${GREEN}-f, --speed-factor''${RESET} N   Relative speed, higher = preferred (default: 2)"
      echo -e "  ''${GREEN}-h, --help''${RESET}             Show this help message"
      echo ""
      echo -e "''${BOLD}Modes:''${RESET}"
      echo -e "  ''${YELLOW}With host:''${RESET}    nxbuild semi .#iso"
      echo -e "              Uses --builders ssh://host (ad-hoc, no setup needed)"
      echo -e "  ''${YELLOW}Without host:''${RESET} nxbuild .#iso"
      echo -e "              Uses nix.buildMachines (requires host config)"
      echo ""
      echo -e "''${BOLD}Examples:''${RESET}"
      echo -e "  nxbuild ''${YELLOW}semi''${RESET} ''${BLUE}.#iso''${RESET}                    Build ISO on semi (ad-hoc)"
      echo -e "  nxbuild ''${BLUE}.#iso''${RESET}                          Build ISO (configured builders)"
      echo -e "  nxbuild ''${YELLOW}dsd''${RESET} -j 4 ''${BLUE}nixpkgs#hello''${RESET}             4 jobs on dsd"
      echo -e "  nxbuild ''${YELLOW}user@host''${RESET} ''${BLUE}nixpkgs#hello''${RESET}             With explicit SSH user"
      exit 0
    }

    if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
      show_help
    fi

    system=$(nix eval --raw --expr 'builtins.currentSystem' 2>/dev/null || echo x86_64-linux)
    max_jobs=8
    speed_factor=2
    host=""
    nix_args=()

    # If first arg doesn't look like a flag or nix target, treat it as a host
    case "$1" in
      -*) ;;           # flag → not a host
      .#*) ;;          # flake output → not a host
      *#*) ;;          # nixpkgs#hello → not a host
      *) host="$1"; shift ;;
    esac

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -s|--system)       system="$2";       shift 2 ;;
        -j|--max-jobs)     max_jobs="$2";     shift 2 ;;
        -f|--speed-factor) speed_factor="$2"; shift 2 ;;
        -h|--help)         show_help ;;
        *) nix_args+=("$1"); shift ;;
      esac
    done

    echo -e "''${BOLD}''${CYAN}nxbuild''${RESET}"
    if [[ -n "$host" ]]; then
      echo -e "  ''${GREEN}Host''${RESET}   ''${DIM}→''${RESET}  ''${BOLD}''${host}''${RESET} ''${DIM}(ad-hoc)''${RESET}"
      echo -e "  ''${GREEN}Jobs''${RESET}   ''${DIM}→''${RESET}  ''${BOLD}''${max_jobs}''${RESET}"
      echo -e "  ''${GREEN}Speed''${RESET}  ''${DIM}→''${RESET}  ''${BOLD}''${speed_factor}''${RESET}"
    else
      # Show configured builders from /etc/nix/machines
      if [[ -f /etc/nix/machines ]]; then
        while IFS= read -r line; do
          [[ -z "$line" || "$line" =~ ^# ]] && continue
          b_host=$(echo "$line" | awk '{print $1}')
          b_sys=$(echo "$line" | awk '{print $2}')
          b_jobs=$(echo "$line" | awk '{print $4}')
          b_speed=$(echo "$line" | awk '{print $5}')
          echo -e "  ''${GREEN}Builder''${RESET} ''${DIM}→''${RESET}  ''${BOLD}''${b_host}''${RESET} ''${DIM}(''${b_sys} / j''${b_jobs} / f''${b_speed})''${RESET}"
        done < /etc/nix/machines
      else
        echo -e "  ''${GREEN}Mode''${RESET}   ''${DIM}→''${RESET}  ''${BOLD}configured builders''${RESET}"
      fi
    fi
    echo -e "  ''${GREEN}System''${RESET} ''${DIM}→''${RESET}  ''${BOLD}''${system}''${RESET}"
    if [[ ''${#nix_args[@]} -gt 0 ]]; then
      echo -e "  ''${GREEN}Target''${RESET} ''${DIM}→''${RESET}  ''${YELLOW}''${nix_args[*]}''${RESET}"
    fi
    echo ""

    if [[ -n "$host" ]]; then
      nix build --system "$system" \
        --builders "ssh://$host $system - $max_jobs $speed_factor" \
        "''${nix_args[@]+"''${nix_args[@]}"}"
    elif [[ -f /etc/nix/machines ]] && { [[ $max_jobs -ne 8 ]] || [[ $speed_factor -ne 2 ]]; }; then
      # Override configured builders with -j/-f values
      builders=""
      while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        b_host=$(echo "$line" | awk '{print $1}')
        b_sys=$(echo "$line" | awk '{print $2}')
        b_key=$(echo "$line" | awk '{print $3}')
        b_feat=$(echo "$line" | awk '{print $7}')
        builders+="ssh://$b_host $b_sys $b_key $max_jobs $speed_factor $b_feat "
      done < /etc/nix/machines
      nix build --system "$system" \
        --builders "$builders" \
        "''${nix_args[@]+"''${nix_args[@]}"}"
    else
      nix build --system "$system" "''${nix_args[@]+"''${nix_args[@]}"}"
    fi
  '';
in
{
  home = {
    shellAliases = {
      c = "clear";
      d = "setsid $@ &>/dev/null"; # run command in background
      cp = "printf '\\033[1;32m' && cp -rv";
      rm = "printf '\\033[1;31m' && rm -rIv";
      rcp = "printf '\\033[1;32m' && rsync -r --info=progress2,stats2 --outbuf=L";
      mkdir = "printf '\\033[1;33m' && mkdir -pv";
      isodate = ''date -u "+%Y-%m-%dT%H:%M:%SZ"'';
      matrix = "${lib.getExe pkgs.unimatrix} -f -l ocCgGkS -s 96 2&> /dev/null";
      fetch = "${lib.getExe pkgs.fastfetch} -c ${pkgs.fastfetch}/share/fastfetch/presets/examples/10.jsonc";
      font-family = "fc-list : family | ${lib.getExe pkgs.fzf}";
    };

    packages = [
      (pkgs.writeShellScriptBin "help" "$@ --help 2>&1 | ${lib.getExe pkgs.bat} --plain --language=help")
      nxbuild
    ];
  };
}
