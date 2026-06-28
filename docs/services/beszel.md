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
- SSH key stored in sops, copied to PocketBase's data dir via `preStart`
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

## Module

- `modules/nixos/beszel.nix` - agent module with `user` option (drives socket, run-as, linger) plus HUB_URL, KEY, LISTEN, DOCKER_HOST defaults
- Hub config is in `hosts/nixos/obox/services/beszel.nix`
