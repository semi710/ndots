set positional-arguments

# Deploy — current host (no arg) or remote host over SSH
deploy host="":
    @if [ -z "{{host}}" ]; then \
        if [ "$(uname -s)" = "Darwin" ]; then \
            nh darwin switch . -H jp-mbp; \
        else \
            nh os switch .; \
        fi; \
    else \
        case "{{host}}" in \
            obox) \
                nh os switch .#obox --target-host nikhil@obox --build-host nikhil@obox --elevation-strategy passwordless ;; \
            mach) \
                nh os switch .#mach --target-host niksingh710@mach --elevation-strategy passwordless ;; \
            *) \
                nh os switch .#{{host}} --target-host nikhil.singh@{{host}} --elevation-strategy passwordless ;; \
        esac; \
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

# Format nix files
fmt:
    treefmt

# Update flake lock
update:
    nix flake update

# Check flake (eval all configs)
check:
    nix flake check

# Garbage collect — all profiles (needs sudo)
gc:
    sudo nh clean all
