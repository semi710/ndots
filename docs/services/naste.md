# naste

[naste](https://github.com/semi710/naste) is a minimal, self-hosted paste service. No database, no frameworks, just files. The server runs on obox, the CLI client is available on all hosts via home-manager.

## Architecture

```
naste (CLI) → POST /api/paste → naste-server (obox:8080) → filesystem
                                    ↓
                            public/ private/ metadata/
```

Caddy proxies `paste.semi.sh` to `localhost:8080` on obox. Private pastes require HTTP Basic Auth.

## Server (obox)

Runs as a NixOS system service via `hosts/nixos/obox/services/naste.nix`:

```nix
services.naste-server = {
  enable = true;
  port = 8080;
  openFirewall = false;  # Caddy proxies
  private.userFile = config.sops.secrets."naste/user".path;
  private.passFile = config.sops.secrets."naste/pass".path;
};
```

Secrets in `secrets/server.yaml`:

```yaml
naste:
    user: admin
    pass: your-secret-password
```

The naste module includes its own package via `withPackages` wrapper, so no overlay is needed.

## Client (all hosts)

The CLI client is enabled in `modules/home/naste.nix` (imported by the shared home module):

```nix
programs.naste-client = {
  enable = true;
  endpoint = "https://paste.semi.sh";
};
```

All home-manager users get the `naste` CLI with the endpoint pre-configured. No private credentials here.

## Private Credentials

Hosts with sops add private credentials in their user config:

### mach, jp-mbp (standalone sops)

```nix
sops.secrets."naste/user" = { sopsFile = "${flake}/secrets/server.yaml"; };
sops.secrets."naste/pass" = { sopsFile = "${flake}/secrets/server.yaml"; };
programs.naste-client.private = {
  userFile = config.sops.secrets."naste/user".path;
  passFile = config.sops.secrets."naste/pass".path;
};
```

### semi, dsd (shared via workstation.nix)

```nix
hm.sops.secrets."naste/user".sopsFile = "${flake}/secrets/server.yaml";
hm.sops.secrets."naste/pass".sopsFile = "${flake}/secrets/server.yaml";
hm.programs.naste-client.private = {
  userFile = config.hm.sops.secrets."naste/user".path;
  passFile = config.hm.sops.secrets."naste/pass".path;
};
```

### Standalone home (hosts/home/)

No private credentials. Public paste access only (endpoint from shared module).

!!! note "First deploy after adding secrets"
    Start a new SSH session after deploying. The `PASTE_USER_FILE` and `PASTE_PASS_FILE` session variables are set by home-manager at login.

## Usage

```bash
# Create a paste
echo "hello" | naste
naste file.go
naste -s mycode < script.sh

# Private paste (requires creds)
echo "secret" | naste -p -s secrets

# Fetch a paste
naste get hello
naste get -p hello      # private (uses creds or prompts)
```

## Files

- `hosts/nixos/obox/services/naste.nix` - server config + sops secrets
- `modules/home/naste.nix` - CLI client (endpoint only, shared by all hosts)
- `hosts/nixos/common/workstation.nix` - private creds for semi + dsd
- `hosts/nixos/mach/users/niksingh710.nix` - private creds for mach
- `hosts/darwin/jp-mbp/users/nikhil.singh.nix` - private creds for jp-mbp
