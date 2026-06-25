# FileBrowser Quantum

[FileBrowser Quantum](https://github.com/gtsteffaniak/filebrowser) is a web-based file manager. Runs on all NixOS hosts.

## Configuration

- Runs as **root** for full filesystem access
- **Tailscale-only** — port not opened in firewall, `tailscale0` is a trusted interface
- Admin credentials per-host via sops — user is hostname, password is `<host>@filebrowser`
- Update checks disabled
- Sources: `/` (filesystem root) + user home (auto-added)

## Per-Host Sources

| Host | Extra sources |
|------|---------------|
| mach | `/run/media/niksingh710/` (external media) |
| dsd | `/home` (all users) |
| semi | — (default `/` + home) |
| obox | — (default `/` + home) |

## Access

```
http://<hostname>:<port>
```

Login: `<hostname>` / `<host>@filebrowser`

Only reachable over Tailscale. Not exposed publicly.

## Module

`modules/nixos/filebrowser.nix`:

```nix
services.filebrowser-quantum = {
  enable = true;
  home = "/home/<user>";     # auto-added as source
  sources = [ "/" ];          # extra sources
  passwordFile = config.sops.secrets."filebrowser/<host>".path;
};
```

## Secrets

Passwords stored in sops:

- `secrets/server.yaml` → `filebrowser.obox`, `filebrowser.mach`
- `secrets/office.yaml` → `filebrowser.semi`, `filebrowser.dsd`

## Troubleshooting

### Service fails to start

```bash
# Clear stale database
sudo rm -rf /var/lib/filebrowser-quantum/*
sudo systemctl reset-failed filebrowser-quantum
sudo systemctl start filebrowser-quantum
```

### "Something went wrong" on landing page

The `/` source indexes the entire filesystem on startup. If the index is corrupt, clear the state dir and restart. If it persists, reduce sources to avoid `/proc`, `/sys`, `/dev`.
