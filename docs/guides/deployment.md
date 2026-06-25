# Deployment

All deployment is handled via `just` recipes using [nh](https://github.com/nix-community/nh).

## Commands

```bash
just deploy              # Current host (auto-detects NixOS vs Darwin)
just deploy obox         # Remote deploy to obox (builds on obox)
just deploy mach         # Remote deploy to mach
just deploy dsd          # Remote deploy to dsd
just deploy semi         # Remote deploy to semi
just home nikhil         # Home-manager only (run on target machine)
```

## How It Works

`just deploy` auto-detects the platform:

- **Darwin** → `nh darwin switch . -H jp-mbp`
- **NixOS (local)** → `nh os switch .`
- **NixOS (remote)** → `nh os switch .#<host> --target-host <user>@<host>`

Remote hosts use passwordless sudo (`--elevation-strategy passwordless`).

## Other Commands

```bash
just build <host>   # Dry build (eval only, no compilation)
just iso            # Build installer ISO
just fmt            # Format nix files (treefmt)
just update         # Update flake lock
just check          # Check flake (eval all configs)
just gc             # Garbage collect all profiles
```

## SSH Host Aliases

Ensure your SSH config has entries for each host (or use Tailscale MagicDNS):

```
Host obox
    HostName obox
    User nikhil

Host mach
    HostName mach
    User niksingh710

Host semi
    HostName semi
    User nikhil.singh

Host dsd
    HostName dsd
    User nikhil.singh
```

Tailscale MagicDNS resolves hostnames automatically - no `/etc/hosts` entries needed.
