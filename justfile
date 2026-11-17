set positional-arguments

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
            nh home switch .#$(whoami); \
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

# Deploy home-manager only (run on the target machine after SSH)
home user="nikhil":
    nh home switch .#{{user}}

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

# Check flake (eval all configs)
check:
    nix flake check

# Garbage collect - all profiles (needs sudo)
gc:
    sudo nh clean all
