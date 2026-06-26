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

Agent config varies by host type:

| Host | Runs as | Docker socket | Notes |
|------|---------|---------------|-------|
| obox | DynamicUser | system (`/var/run/docker.sock`) | PrivateUsers=false |
| semi, dsd | user (nikhil.singh) | rootless (`/run/user/1000/docker.sock`) | DynamicUser=false |
| mach | user (niksingh710) | rootless (`/run/user/1000/docker.sock`) | SKIP_GPU=true |

### Why agents run as user on workstations

Rootless Docker socket is at `/run/user/<uid>/docker.sock` inside a `0700` directory. The agent must run as that user to traverse the path. `DynamicUser=false` + `User=<username>` fixes this.

### mach GPU workaround

AMD GPU sysfs reading causes a kernel panic in beszel. `SKIP_GPU=true` disables GPU monitoring.

- Bug: https://github.com/henrygd/beszel/issues/1799

## Module

- `modules/nixos/beszel.nix` - agent module with options for HUB_URL, KEY, LISTEN, DOCKER_HOST, TOKEN_FILE
- Hub config is in `hosts/nixos/obox/services/beszel.nix`
