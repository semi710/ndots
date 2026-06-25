# Secrets Management

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using [age](https://age-encryption.org/) encryption.

## Key Generation

Each machine has an age key at `~/.config/sops/age/keys.txt`. Generate with:

```bash
nix run nixpkgs#age-keygen -o ~/.config/sops/age/keys.txt
```

The public key (for `.sops.yaml`) is shown by:

```bash
nix run nixpkgs#age-keygen -y ~/.config/sops/age/keys.txt
```

## File Layout

| File | Key | Hosts | Contents |
|------|-----|-------|----------|
| `secrets/office.yaml` | office age key | semi, dsd | Tailscale auth, nix access token, syncthing certs, filebrowser passwords |
| `secrets/server.yaml` | office age key | obox, mach | Tailscale auth, beszel creds/SSH key, filebrowser passwords |
| `secrets/keys.yaml` | personal age key | — | Age key generation |

## .sops.yaml

```yaml
keys:
  - &personal age1qq74n2h6sq8gv843dc67k3jczru768pq6jg3zg4ycmrtqdyfhfes803ncy
  - &office age1kkh7046u0m22jsw9cclsdlefxyzlmpxhwm58n3qjrjshjqn2lq5qey6p7e
creation_rules:
  - path_regex: ^secrets/keys\.yaml$
    key_groups:
      - age: [*personal]
  - path_regex: ^secrets/(office|server)\.yaml$
    key_groups:
      - age: [*office]
```

## Editing Secrets

```bash
# Decrypt and edit
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt nix run nixpkgs#sops -- -i secrets/server.yaml

# Decrypt to stdout
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt nix run nixpkgs#sops -- -d secrets/server.yaml

# Encrypt a plaintext file (copy then encrypt in place)
cp decrypted.yaml secrets/server.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt nix run nixpkgs#sops -- -i -e secrets/server.yaml
```

## Adding a New Secret

1. Decrypt the appropriate sops file
2. Add your key-value pair
3. Re-encrypt
4. Wire in the host config:

```nix
sops.secrets."myapp/password" = { };
# Use it:
environmentFile = config.sops.secrets."myapp/password".path;
```

## Sops Templates

For composing env files from multiple secrets:

```nix
sops.templates."myapp-env" = {
  content = ''
    USERNAME=${config.sops.placeholder."myapp/username"}
    PASSWORD=${config.sops.placeholder."myapp/password"}
  '';
};
```

The template file is rendered at activation time with actual secret values.
