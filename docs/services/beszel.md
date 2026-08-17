# Beszel Monitoring

[Beszel](https://github.com/henrygd/beszel) is a lightweight server monitoring tool. The hub runs on obox, agents run on all NixOS hosts.

## Architecture

```
obox (hub)  ←── SSH ──  mach (agent)
            ←── SSH ──  semi (agent)
            ←── SSH ──  dsd (agent)
            ←── SSH ──  obox (agent, self-monitoring)
```

The hub connects to agents via SSH using a dedicated key. Agents report system stats (CPU, RAM, disk, temp) and Docker container stats every 60 seconds.

## Hub (obox)

- Runs as a systemd service
- SSH key stored in sops, copied to PocketBase's data dir via `ExecStartPre`
- Admin credentials in sops (`secrets/server.yaml`)
- Universal token for agent auto-enrollment (one-time setup)

### Universal Token Setup

After a fresh hub database, enable the universal token:

```bash
# 1. Get JWT from hub
JWT=$(curl -s http://localhost:<port>/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"<email>","password":"<pass>"}' | jq -r .token)

# 2. Enable universal token
curl "http://localhost:<port>/api/beszel/universal-token?enable=1&permanent=1&token=<token>" \
  -H "Authorization: $JWT"
```

## Agent (all hosts)

The shared module (`modules/nixos/beszel.nix`) exposes a `services.beszel.agent.user` option:

- **Set** (rootless docker hosts): agent targets `/run/user/1000/docker.sock`, runs as that user with `DynamicUser=false`, and enables native `users.users.<user>.linger` so the socket exists at boot without a login session.
- **Unset / null** (system docker): agent targets `/var/run/docker.sock` as a DynamicUser.

Per-host config is limited to the user, secrets, and host-specific env vars:

| Host | `agent.user` | Extra env | Notes |
|------|-------------|-----------|-------|
| obox | `nikhil` | — | Also runs the hub |
| semi, dsd | `nikhil.singh` | — | — |
| mach | `niksingh710` | `SKIP_GPU=true` | AMD GPU sysfs panic workaround ([#1799](https://github.com/henrygd/beszel/issues/1799)) |

## Adding a New Agent Host

The SSH key is shared (hardcoded in the module), so onboarding is minimal.

### 1. Token

Ensure `beszel/token` exists in the host's sops file (`secrets/server.yaml` for obox/mach, `secrets/office.yaml` for semi/dsd). The shared module reads it automatically.

### 2. Module Import

For NixOS hosts, `common/cloud.nix` or `common/workstation.nix` already imports `nixosModules.beszel`. The agent is enabled by default. Per-host config:

```nix
services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
services.beszel.agent.user = "<username>";  # for rootless docker, else omit
```

### 3. Non-NixOS Devices

For non-NixOS devices (e.g., a remote server), run the Docker image:

```bash
docker run -d --network host --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYwmNqGPWjYdAoVH2IM3tp/liL8sHNF4/kladhQUzSQ beszel-hub@obox' \
  -e HUB_URL='https://beszel.semi.sh' \
  -e TOKEN='<from sops: secrets/server.yaml beszel.token>' \
  henrygd/beszel-agent:latest
```

KEY is public (encrypts metrics), TOKEN is secret (from sops).

## Module

- `modules/nixos/beszel.nix` - agent module with `user` option (drives socket, run-as, linger) plus HUB_URL, KEY, LISTEN, DOCKER_HOST defaults
- Hub config is in `hosts/nixos/common/cloud.nix` (shared by obox and bbox)
