set positional-arguments

# Sync app configs into misc/ and push. Each app exports its live state to
# its snapshot: no override file sits in the app's config dir, so the app
# always runs on its own defaults and this is pure versioning (restore with
# the app's import).
app-sync app="vorssaint":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{app}}" in
      vorssaint)
        mkdir -p misc/vorssaint
        /Applications/Vorssaint.app/Contents/MacOS/Vorssaint --export-settings misc/vorssaint/settings.plist
        ;;
      *)
        echo "app-sync: unknown app '{{app}}'"
        exit 1
        ;;
    esac
    git add misc/
    if git diff --cached --quiet; then
      echo "app-sync: no changes"
      exit 0
    fi
    git commit -m "chore(apps): sync {{app}} config"
    git push

# Deploy - auto-detects local or remote, NixOS or home-manager:
#   just deploy                            → current machine (darwin/nixos/HM)
#   just deploy <user>@<host> [port]       → SSH, detect type, deploy
#   just deploy <host> [port]              → SSH, detect, user from flake (NixOS only)
deploy target="" port="22":
    @if [ -z "{{target}}" ]; then \
        if [ "$(uname -s)" = "Darwin" ]; then \
            nh darwin switch . -H $(hostname -s); \
        elif [ -f /etc/NIXOS ]; then \
            nh os switch .; \
        else \
            sys=$(nix eval --impure --raw --expr builtins.currentSystem); \
            nix build --accept-flake-config .#legacyPackages.$sys.homeConfigurations.$(whoami).activationPackage && ./result/activate; \
        fi; \
    else \
        t="{{target}}"; u=""; h="$t"; \
        case "$t" in *@*) u="${t%%@*}"; h="${t##*@}";; esac; \
        p="{{port}}"; case "$p" in -p*) p="${p#-p}";; port=*) p="${p#port=}";; esac; \
        [ -z "$p" ] && p=22; \
        cm="-o ControlMaster=auto -o ControlPath=/tmp/just-deploy-%r@%h:%p -o ControlPersist=300 -o ServerAliveInterval=30 -o ServerAliveCountMax=20"; \
        info=$(ssh $cm -o ConnectTimeout=10 -p "$p" "$t" 'echo "$(test -f /etc/NIXOS && echo yes || echo no):$(hostname -s):$(uname -s)"' 2>/dev/null) || \
            { echo "✗ can't reach $t on port $p"; exit 1; }; \
        is_nixos=$(echo "$info" | cut -d: -f1); \
        rh=$(echo "$info" | cut -d: -f2); \
        os=$(echo "$info" | cut -d: -f3); \
        if [ "$is_nixos" = "yes" ]; then \
            if [ -z "$u" ]; then \
                u=$(nix eval --raw .#nixosConfigurations.$rh.config.users.users --apply 'users: builtins.concatStringsSep " " (builtins.filter (n: users.${n}.isNormalUser or false) (builtins.attrNames users))' 2>/dev/null) || \
                    { echo "✗ can't lookup user for $rh"; exit 1; }; \
                case "$u" in \
                    *\ *) echo "✗ multiple users on $rh: $u - use: just deploy <user>@$h"; exit 1 ;; \
                esac; \
            fi; \
            nh os switch .#$rh --target-host $u@$h --build-host $u@$h --elevation-strategy passwordless; \
        elif [ "$os" = "Linux" ]; then \
            if [ -z "$u" ]; then \
                echo "✗ user required for HM deploy: just deploy <user>@$h"; exit 1; \
            fi; \
            rsync -az --delete --exclude='.git' --exclude='result' --exclude='.direnv' -e "ssh $cm -p $p" ./ "$u@$h:/tmp/ndots/"; \
            ssh $cm -o ConnectTimeout=10 -p "$p" "$u@$h" \
                "cd /tmp/ndots && NIX_CONFIG='accept-flake-config = true' nix build .#legacyPackages.x86_64-linux.homeConfigurations.$u.activationPackage && ./result/activate"; \
        else \
            echo "✗ $os on $h - remote deploy not supported"; exit 1; \
        fi; \
    fi

# nh cannot address nix-wire's legacyPackages.homeConfigurations.<name>, so
# deploy home-manager only from this flake, standalone HM, any host
home user="nikhil":
    nix build --accept-flake-config .#legacyPackages.$(nix eval --impure --raw --expr builtins.currentSystem).homeConfigurations.{{user}}.activationPackage && ./result/activate

# Dry build (eval only, no compilation)
build host:
    @case "{{host}}" in \
        jp-mbp) nh darwin build . -H jp-mbp --dry ;; \
        *) nh os build .#{{host}} --dry ;; \
    esac

# Build ISO
iso:
    nix build .#iso

# Fetch ZMK firmware from semi710/zmk-config CI (waits for in-progress run; downloads to zmk/out/)
zmk:
    rid=$(gh run list -R semi710/zmk-config -w "Build ZMK Firmware" -L1 --json databaseId -q '.[0].databaseId') && \
    gh run watch "$rid" --exit-status -i 5 && \
    gh run download "$rid" -R semi710/zmk-config -n firmware -D zmk/out

# Build ZMK firmware locally via nix
zmk-build:
    nix build .#zmk

# Serve docs locally (http://0.0.0.0:<random-port>)
doc:
    PORT=$(shuf -i 8000-9000 -n 1) && echo "→ http://0.0.0.0:$PORT" && nix run .#docs -- serve -a 0.0.0.0:$PORT --quiet 2>&1 | grep -v "│"

# Format nix files
fmt:
    treefmt

# Update flake lock
update:
    nix flake update

# Eval every deploy target - host toplevels and local home configs. nix
# flake check does NOT evaluate these, which is how nixpkgs rename fallout
# (pnpm_11-style) reaches a deploy instead of a check
check:
    #!/usr/bin/env bash
    set -euo pipefail
    sys=$(nix eval --impure --raw --expr builtins.currentSystem)
    fail=0
    run() { # run <label> <attr-path>
      local out
      if out=$(nix eval --raw "$2.drvPath" --accept-flake-config 2>&1); then
        echo "  ok    $1"
      else
        echo "  FAIL  $1"
        echo "$out" | tail -4 | sed 's/^/        /'
        fail=1
      fi
    }
    for u in $(nix eval --json ".#legacyPackages.$sys.homeConfigurations" --apply builtins.attrNames | jq -r '.[]'); do
      run "home/$u" ".#legacyPackages.$sys.homeConfigurations.$u.activationPackage"
    done
    for h in $(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]'); do
      [ "$h" = "anywhere" ] && continue # template, needs generated hardware config
      run "nixos/$h" ".#nixosConfigurations.$h.config.system.build.toplevel"
    done
    for h in $(nix eval --json .#darwinConfigurations --apply builtins.attrNames | jq -r '.[]'); do
      run "darwin/$h" ".#darwinConfigurations.$h.config.system.build.toplevel"
    done
    [ "$fail" -eq 0 ] && echo "all deploy targets evaluate" || { echo "eval failures above"; exit 1; }

# Garbage collect - all profiles (needs sudo)
gc:
    sudo nh clean all
