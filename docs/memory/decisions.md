# Key Decisions

Record of architectural decisions and their rationale. Update when making new decisions.

## Beszel hub SSH key: preStart copy to PocketBase data dir

**Decision:** Copy sops secret to `/var/lib/beszel-hub/beszel_data/id_ed25519` via `preStart`, not to the working directory root.

**Why:** PocketBase (beszel's DB) looks for the SSH key in its `DataDir`, which is `beszel_data/`. Putting it at the service root doesn't work.

## Beszel agent runs as user on workstations

**Decision:** `DynamicUser=false`, `User=<username>` on semi/dsd/mach.

**Why:** Rootless Docker socket is at `/run/user/<uid>/docker.sock` inside a `0700` directory. A dynamic user can't traverse it. The agent must run as the actual user.

## Beszel agent on obox: PrivateUsers=false

**Decision:** Keep `DynamicUser=true` but set `PrivateUsers=false` on obox.

**Why:** System Docker socket access requires `PrivateUsers=false`. Rootless Docker isn't used on obox, so the agent can stay dynamic.

## FileBrowser Quantum runs as root

**Decision:** Run as root on all hosts.

**Why:** User home directories on NixOS are `0700`. Running as a specific user can't access other users' homes. Root sees everything. Acceptable because the service is Tailscale-only (not exposed publicly).

## Caddy config is imperative

**Decision:** `configFile = "/etc/caddy/Caddyfile"` — editable on the box, no rebuild.

**Why:** Adding/removing routes shouldn't require a NixOS rebuild. Caddy reloads with `systemctl reload caddy`. Trade-off: config isn't declaratively tracked, but operational speed matters more here.

## Sops split: office vs server

**Decision:** Two sops files — `office.yaml` (semi, dsd) and `server.yaml` (obox, mach). Both encrypted with the office age key.

**Why:** Different trust boundaries. Office machines share Juspay work context. Servers share infrastructure creds. Using the same key for both simplifies key management while keeping the secret sets separate.

## Stirling PDF: no env-based admin

**Decision:** Configure admin via UI, not env vars. Removed sops creds for stirling.

**Why:** Stirling's env-based admin only works on first boot with an empty DB. If the DB exists, the env vars are ignored. Managing via UI is simpler and avoids stale credentials. Clear `/var/lib/stirling-pdf/*` to reset.

## Excalidraw: deferred

**Decision:** Removed excalidraw + excalidraw-room containers. Deferred to later.

**Why:** Collaboration requires a separate WebSocket server (`excalidraw-room`), and `REACT_APP_BACKEND_V2_WS_BASE_URL` must be a public domain (browser-side React env var). Needs Caddy routes + DNS setup. Not worth the complexity right now.

## MkDocs Material for docs

**Decision:** Use MkDocs Material (not custom HTML, not Jekyll, not Docusaurus).

**Why:** Docs are content-driven, not UI-driven. Material is a polished, production-grade theme with search, sidebar nav, dark mode — all from markdown. Building custom HTML for docs would be over-engineering. One config file + GitHub Action to deploy.

## nix-wire for auto-wiring

**Decision:** Use nix-wire (personal library) instead of manual module/ host registration.

**Why:** Auto-imports modules and hosts from directory structure. `hosts/nixos/<name>/default.nix` → `nixosConfigurations.<name>` automatically. Eliminates boilerplate and keeps the flake.nix minimal (just inputs + `mkFlake`). Hostname is auto-set from directory name.

## obox skips the base module

**Decision:** obox imports `flakeModules.nix` directly, not `nixosModules.default`.

**Why:** obox is a headless server. The base module pulls in stylix, home-manager default (with tons of fonts), and the cachyos kernel overlay — all unnecessary on a VPS. Importing just the nix settings keeps it lean.

## Custom packages via overlay, not per-module

**Decision:** All custom packages in `packages/` are auto-discovered and re-exposed via `overlays/packages.nix` into `pkgs`.

**Why:** One place to define, available everywhere as `pkgs.<name>`. No need to pass flake outputs around in modules. The overlay also handles `opencode-vim` patching (stale hashes + bun version) and `appstream` Darwin fix.

## Standalone home-manager configs in hosts/home/

**Decision:** `hosts/home/<user>.nix` for standalone (non-NixOS) home-manager users.

**Why:** Some users (nikhil, admin) run home-manager on systems not managed by this flake (e.g., another NixOS config, or a foreign distro). These compose `homeModules.default` + `homeModules.home-only` (which adds `flakeModules.nix` for nix settings).

## DeathChest over GraveSafe for Minecraft

**Decision:** Use DeathChest 1.5.7 instead of GraveSafe 1.0.0.

**Why:** GraveSafe duped armor — it collected `getContents()` (all 41 slots incl armor+offhand) then re-collected `getArmorContents()` + `getItemInOffHand()`, adding them twice. DeathChest doesn't have this bug.

## vim-motions-pi with clipboard + escape sequence

**Decision:** Use a forked vim-motions-pi (`feat/clipboard-and-escape` branch) with OSC52 clipboard + `jk` escape.

**Why:** Upstream vim-motions-pi didn't support clipboard integration or custom escape sequences. The fork adds `VIM_MOTION_PI_ESCAPE_SEQUENCE = "jk"` and `VIM_MOTION_PI_CLIPBOARD_COMMAND = copy` for SSH-friendly clipboard.
