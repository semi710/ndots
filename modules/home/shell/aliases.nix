{ pkgs, lib, ... }:
let
  nxbuild = pkgs.writeShellScriptBin "nxbuild" ''
    # nxbuild - Build nix packages on remote builders
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
      echo -e "''${BOLD}Usage:''${RESET} nxbuild ''${YELLOW}<host>''${RESET} [options...] [nix build args...]"
      echo ""
      echo -e "''${BOLD}Options:''${RESET}"
      echo -e "  ''${GREEN}-s, --system''${RESET} SYS       Target system (default: current system)"
      echo -e "  ''${GREEN}-j, --max-jobs''${RESET} N       Max parallel builds on remote (default: 8)"
      echo -e "  ''${GREEN}-f, --speed-factor''${RESET} N   Relative speed, higher = preferred (default: 2)"
      echo -e "  ''${GREEN}-h, --help''${RESET}             Show this help message"
      echo ""
      echo -e "''${BOLD}Examples:''${RESET}"
      echo -e "  nxbuild ''${YELLOW}dsd''${RESET}                                Build current flake on dsd"
      echo -e "  nxbuild ''${YELLOW}dsd''${RESET} ''${BLUE}nixpkgs#hello''${RESET}                  Build hello on dsd"
      echo -e "  nxbuild ''${YELLOW}dsd''${RESET} -s x86_64-linux ''${BLUE}nixpkgs#hello''${RESET}  Explicit system"
      echo -e "  nxbuild ''${YELLOW}dsd''${RESET} -j 4 -f 3 ''${BLUE}nixpkgs#hello''${RESET}        4 jobs, speed factor 3"
      echo -e "  nxbuild ''${YELLOW}user@host''${RESET} ''${BLUE}nixpkgs#hello''${RESET}             With explicit SSH user"
      echo ""
      echo -e "''${DIM}The <host> can be any SSH-accessible machine with nix installed."
      echo -e "SSH user defaults to \$USER, override with user@host syntax."
      echo -e ""
      echo -e "Builder spec: ssh://host system - maxJobs speedFactor"
      echo -e "  maxJobs:     parallel builds on remote (default: 8)"
      echo -e "  speedFactor: relative speed, higher = nix prefers this builder (default: 2)''${RESET}"
      exit 0
    }

    if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
      show_help
    fi

    host="''${1}"
    shift

    system=$(nix eval --raw --expr 'builtins.currentSystem' 2>/dev/null || echo x86_64-linux)
    max_jobs=8
    speed_factor=2
    nix_args=()

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
    echo -e "  ''${GREEN}Host''${RESET}   ''${DIM}→''${RESET}  ''${BOLD}''${host}''${RESET}"
    echo -e "  ''${GREEN}System''${RESET} ''${DIM}→''${RESET}  ''${BOLD}''${system}''${RESET}"
    echo -e "  ''${GREEN}Jobs''${RESET}   ''${DIM}→''${RESET}  ''${BOLD}''${max_jobs}''${RESET}"
    echo -e "  ''${GREEN}Speed''${RESET}  ''${DIM}→''${RESET}  ''${BOLD}''${speed_factor}''${RESET}"
    if [[ ''${#nix_args[@]} -gt 0 ]]; then
    echo -e "  ''${GREEN}Target''${RESET} ''${DIM}→''${RESET}  ''${YELLOW}''${nix_args[*]}''${RESET}"
    fi
    echo ""

    nix build --system "$system" \
      --builders "ssh://$host $system - $max_jobs $speed_factor" \
      "''${nix_args[@]+"''${nix_args[@]}"}"
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
    };

    packages = [
      (pkgs.writeShellScriptBin "help" "$@ --help 2>&1 | ${lib.getExe pkgs.bat} --plain --language=help")
      nxbuild
    ];
  };
}
